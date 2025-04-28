class LoanService
  attr_reader :loan, :user, :errors

  def initialize(loan_or_user)
    if loan_or_user.is_a?(Loan)
      @loan = loan_or_user
      @user = loan_or_user.user
    elsif loan_or_user.is_a?(User)
      @user = loan_or_user
      @loan = nil
    else
      raise ArgumentError, "Must provide a Loan or User"
    end
    @errors = []
  end

  # Apply for a new loan
  # @param amount [Decimal] Requested loan amount
  # @param term_days [Integer] Loan term in days
  # @param purpose [String] Purpose of the loan
  # @param options [Hash] Additional loan options
  # @return [Result] Success result with loan details or failure result
  def apply_for_loan(amount, term_days, purpose, options = {})
    # Validate inputs
    return Result.failure({ message: "Amount must be greater than zero", code: :invalid_amount }) unless amount.to_f > 0
    return Result.failure({ message: "Term must be at least 1 day", code: :invalid_term }) unless term_days.to_i > 0
    return Result.failure({ message: "Purpose is required", code: :missing_purpose }) if purpose.blank?
    
    # Check user eligibility
    eligibility_result = check_eligibility(amount)
    return eligibility_result if eligibility_result.failure?
    
    # Get user's wallet
    wallet = user.wallet
    return Result.failure({ message: "User has no active wallet", code: :no_wallet }) unless wallet&.active?
    
    # Create the loan
    ActiveRecord::Base.transaction do
      begin
        loan = Loan.new(
          user: user,
          amount: amount,
          term_days: term_days,
          purpose: purpose,
          interest_rate: calculate_interest_rate(user, amount),
          status: 'pending',
          due_date: Date.current + term_days.days,
          metadata: options
        )
        
        if loan.save
          # Also create a credit score snapshot
          credit_score = CreditScoreService.new(user).get_current_score
          loan.update(credit_score_at_application: credit_score.score) if credit_score.success?
          
          Result.success({
            message: "Loan application submitted successfully",
            loan: loan,
            application_id: loan.id
          })
        else
          Result.failure({
            message: "Failed to create loan application",
            code: :creation_failed,
            details: loan.errors.full_messages
          })
        end
      rescue => e
        Rails.logger.error("Error creating loan: #{e.message}")
        Result.failure({
          message: "An error occurred while processing your loan application",
          code: :system_error,
          details: e.message
        })
      end
    end
  end
  
  # Check if a user is eligible for a loan of the specified amount
  # @param amount [Decimal] The requested loan amount
  # @return [Result] Success if eligible, failure otherwise with reason
  def check_eligibility(amount)
    # Validate input
    return Result.failure({ message: "Amount must be greater than zero", code: :invalid_amount }) unless amount.to_f > 0
    
    # Check if user has any active loans
    if Loan.where(user: user, status: ['active', 'overdue']).exists?
      return Result.failure({
        message: "You have an active loan that must be repaid first",
        code: :existing_loan
      })
    end
    
    # Check credit score
    credit_score_result = CreditScoreService.new(user).get_current_score
    return credit_score_result if credit_score_result.failure?
    
    credit_score = credit_score_result.data[:score]
    
    # If score is too low, reject application
    if credit_score < 500
      return Result.failure({
        message: "Your credit score is too low for loan approval",
        code: :low_credit_score,
        details: { current_score: credit_score, minimum_required: 500 }
      })
    end
    
    # Calculate maximum eligible amount based on credit score
    max_amount = calculate_max_loan_amount(credit_score)
    
    if amount > max_amount
      return Result.failure({
        message: "The requested amount exceeds your current loan limit",
        code: :exceeds_limit,
        details: { requested: amount, maximum_allowed: max_amount }
      })
    end
    
    # If we get here, the user is eligible
    Result.success({
      eligible: true,
      max_amount: max_amount,
      credit_score: credit_score
    })
  end
  
  # Approve a loan application
  # @param loan_id [Integer] The loan ID to approve
  # @param approver [User] The admin/staff approving the loan
  # @param notes [String] Optional approval notes
  # @return [Result] Success or failure result
  def approve_loan(loan_id, approver, notes = nil)
    # Find the loan
    loan = Loan.find_by(id: loan_id)
    return Result.failure({ message: "Loan not found", code: :not_found }) unless loan
    
    # Verify loan is in pending status
    unless loan.status == 'pending'
      return Result.failure({
        message: "Loan cannot be approved in #{loan.status} status",
        code: :invalid_state
      })
    end
    
    # Verify approver is authorized
    unless approver.admin? || approver.has_role?(:loan_officer)
      return Result.failure({
        message: "You are not authorized to approve loans",
        code: :unauthorized
      })
    end
    
    # Process the approval
    ActiveRecord::Base.transaction do
      begin
        # Update loan status
        loan.update(
          status: 'approved',
          approved_by: approver.id,
          approved_at: Time.current,
          approval_notes: notes
        )
        
        # Create loan disbursement transaction
        disbursal_result = LoanDisbursalService.new(loan).disburse
        
        if disbursal_result.success?
          # Return success result
          Result.success({
            message: "Loan approved and funds disbursed",
            loan: loan,
            transaction: disbursal_result.data[:transaction]
          })
        else
          # If disbursal failed, rollback the transaction
          raise ActiveRecord::Rollback, "Disbursement failed: #{disbursal_result.error_message}"
        end
      rescue => e
        Rails.logger.error("Error approving loan: #{e.message}")
        Result.failure({
          message: "Failed to approve loan",
          code: :approval_failed,
          details: e.message
        })
      end
    end
  end
  
  # Reject a loan application
  # @param loan_id [Integer] The loan ID to reject
  # @param rejector [User] The admin/staff rejecting the loan
  # @param reason [String] Rejection reason
  # @return [Result] Success or failure result
  def reject_loan(loan_id, rejector, reason)
    # Find the loan
    loan = Loan.find_by(id: loan_id)
    return Result.failure({ message: "Loan not found", code: :not_found }) unless loan
    
    # Verify loan is in pending status
    unless loan.status == 'pending'
      return Result.failure({
        message: "Loan cannot be rejected in #{loan.status} status",
        code: :invalid_state
      })
    end
    
    # Verify rejector is authorized
    unless rejector.admin? || rejector.has_role?(:loan_officer)
      return Result.failure({
        message: "You are not authorized to reject loans",
        code: :unauthorized
      })
    end
    
    # Process the rejection
    if loan.update(
        status: 'rejected',
        rejected_by: rejector.id,
        rejected_at: Time.current,
        rejection_reason: reason
      )
      
      # Notify the user
      NotificationService.new(loan.user).send_notification(
        title: "Loan Application Rejected",
        message: "Your loan application has been rejected. Reason: #{reason}",
        category: :loan
      ) if defined?(NotificationService)
      
      Result.success({
        message: "Loan application rejected",
        loan: loan
      })
    else
      Result.failure({
        message: "Failed to reject loan application",
        code: :update_failed,
        details: loan.errors.full_messages
      })
    end
  end
  
  # Make a repayment on the loan
  # @param amount [Decimal] The amount to repay
  # @param payment_method [Symbol] The payment method
  # @param metadata [Hash] Additional payment metadata
  # @return [Result] Success or failure result
  def make_repayment(amount, payment_method, metadata = {})
    # Validate the loan
    return Result.failure({ message: "No loan specified", code: :no_loan_specified }) unless loan
    
    # Validate loan is in a state that can accept payments
    unless ['active', 'overdue'].include?(loan.status)
      return Result.failure({
        message: "Loan is not in a state that can accept payments",
        code: :invalid_loan_state,
        details: { current_state: loan.status }
      })
    end
    
    # Validate amount
    return Result.failure({ message: "Amount must be greater than zero", code: :invalid_amount }) unless amount.to_f > 0
    
    # Process the repayment
    repayment_result = LoanRepaymentService.new(loan).process_repayment(
      amount: amount,
      payment_method: payment_method,
      metadata: metadata
    )
    
    if repayment_result.success?
      # Check if loan is fully repaid
      if loan.reload.remaining_balance <= 0
        loan.update(status: 'paid')
        
        # Notify the user
        NotificationService.new(user).send_notification(
          title: "Loan Fully Repaid",
          message: "Congratulations! Your loan has been fully repaid.",
          category: :loan
        ) if defined?(NotificationService)
      end
      
      Result.success({
        message: "Payment processed successfully",
        transaction: repayment_result.data[:transaction],
        remaining_balance: loan.remaining_balance,
        loan_status: loan.status
      })
    else
      # Return the failure result directly
      repayment_result
    end
  end
  
  # Get details about the user's current loans
  # @return [Result] Success result with loan information
  def get_loan_summary
    active_loans = Loan.where(user: user).where(status: ['pending', 'approved', 'active', 'overdue'])
    
    total_active_balance = active_loans.sum(:remaining_balance)
    monthly_payment_total = active_loans.where(status: ['active', 'overdue']).sum(:monthly_payment)
    
    Result.success({
      active_loans: active_loans,
      total_active_balance: total_active_balance,
      monthly_payment_total: monthly_payment_total,
      loan_count: active_loans.count,
      loan_history_count: Loan.where(user: user).count
    })
  end
  
  private
  
  # Calculate the maximum loan amount based on credit score
  # @param credit_score [Integer] The user's credit score
  # @return [Decimal] The maximum loan amount
  def calculate_max_loan_amount(credit_score)
    case credit_score
    when 0..499
      0 # Not eligible
    when 500..599
      500
    when 600..699
      2000
    when 700..799
      5000
    else # 800+
      10000
    end
  end
  
  # Calculate interest rate based on user profile and amount
  # @param user [User] The user applying for the loan
  # @param amount [Decimal] The loan amount
  # @return [Decimal] The interest rate as a decimal (e.g., 0.05 for 5%)
  def calculate_interest_rate(user, amount)
    # Get credit score
    credit_score_result = CreditScoreService.new(user).get_current_score
    
    # Default base rate
    base_rate = 0.15
    
    # Adjust based on credit score if available
    if credit_score_result.success?
      credit_score = credit_score_result.data[:score]
      
      case credit_score
      when 0..599
        base_rate = 0.20 # High risk
      when 600..699
        base_rate = 0.15 # Medium risk
      when 700..799
        base_rate = 0.10 # Low risk
      else
        base_rate = 0.08 # Very low risk
      end
    end
    
    # Adjust based on loan amount
    if amount < 1000
      base_rate += 0.02 # Small loans have higher rates
    elsif amount > 5000
      base_rate -= 0.01 # Large loans have slightly lower rates
    end
    
    # Adjust based on user history
    if user.loans.where(status: 'paid').count > 3
      base_rate -= 0.02 # Reward for good repayment history
    end
    
    # Ensure rate doesn't go below minimum
    [base_rate, 0.05].max
  end
end
