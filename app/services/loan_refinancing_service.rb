class LoanRefinancingService
  def initialize(user)
    @user = user
  end

  # Check if a loan is eligible for refinancing
  def eligible_for_refinancing?(loan)
    return false unless loan.present?
    return false unless loan.active?
    return false if loan.overdue?

    # Check if the user's credit score has improved since the loan was created
    current_score = @user.current_credit_score&.score || 0
    loan_score = loan_credit_score(loan)

    # Loan must be at least 30 days old to be eligible for refinancing
    days_since_creation = (Date.today - loan.created_at.to_date).to_i
    return false if days_since_creation < 30

    # User must have made at least 2 payments
    return false if loan.loan_repayments.count < 2

    # Credit score must have improved by at least 20 points or be above 650
    score_improved = current_score > loan_score + 20
    good_score = current_score >= 650

    # At least 25% of the loan must be remaining
    remaining_percentage = (loan.amount_due / loan.amount) * 100
    significant_amount_remaining = remaining_percentage >= 25

    # The loan must have at least 30 days remaining
    days_remaining = 0
    if loan.due_date.present?
      days_remaining = (loan.due_date.to_date - Date.today).to_i
    end
    sufficient_time_remaining = days_remaining >= 30

    (score_improved || good_score) && significant_amount_remaining && sufficient_time_remaining
  end

  # Get all loans eligible for refinancing
  def eligible_loans
    @user.loans.active.select { |loan| eligible_for_refinancing?(loan) }
  end

  # Calculate potential savings from refinancing
  def calculate_savings(loan)
    return { savings: 0, new_rate: loan.interest_rate } unless eligible_for_refinancing?(loan)

    # Calculate new interest rate based on current credit score
    current_score = @user.current_credit_score&.score || 0
    new_rate = calculate_new_interest_rate(current_score, loan.loan_type)

    # Only proceed if the new rate is better
    return { savings: 0, new_rate: loan.interest_rate } if new_rate >= loan.interest_rate

    # Calculate remaining interest with current rate
    current_remaining_interest = calculate_remaining_interest(loan, loan.interest_rate)

    # Calculate remaining interest with new rate
    new_remaining_interest = calculate_remaining_interest(loan, new_rate)

    # Calculate savings
    savings = current_remaining_interest - new_remaining_interest

    {
      current_rate: loan.interest_rate,
      new_rate: new_rate,
      rate_difference: loan.interest_rate - new_rate,
      current_remaining_interest: current_remaining_interest,
      new_remaining_interest: new_remaining_interest,
      savings: savings,
      savings_percentage: (savings / current_remaining_interest * 100).round(2)
    }
  end

  # Create a refinancing application
  def create_refinancing_application(loan, params = {})
    return nil unless eligible_for_refinancing?(loan)

    savings_data = calculate_savings(loan)
    return nil if savings_data[:savings] <= 0

    # Create the refinancing application
    LoanRefinancing.create!(
      user: @user,
      original_loan: loan,
      requested_amount: loan.amount_due,
      original_rate: loan.interest_rate,
      requested_rate: savings_data[:new_rate],
      estimated_savings: savings_data[:savings],
      status: :pending,
      reason: params[:reason],
      term_days: params[:term_days] || calculate_new_term_days(loan)
    )
  end

  # Approve a refinancing application
  def approve_refinancing(refinancing)
    return false unless refinancing.pending?

    # Start a transaction to ensure all operations succeed or fail together
    LoanRefinancing.transaction do
      # Create a new loan with the refinanced terms
      new_loan = Loan.create!(
        user: @user,
        amount: refinancing.requested_amount,
        interest_rate: refinancing.requested_rate,
        loan_type: refinancing.original_loan.loan_type,
        term_days: refinancing.term_days,
        status: :approved,
        purpose: "Refinancing of Loan ##{refinancing.original_loan.reference_number}",
        refinanced_from_loan_id: refinancing.original_loan.id
      )

      # Update the refinancing record
      refinancing.update!(
        status: :approved,
        new_loan: new_loan,
        approved_at: Time.current
      )

      # Mark the original loan as refinanced
      refinancing.original_loan.update!(
        status: :refinanced,
        refinanced_to_loan_id: new_loan.id,
        completed_at: Time.current
      )

      # Create a notification for the user
      @user.create_notification(
        title: "Loan Refinancing Approved",
        content: "Your request to refinance loan ##{refinancing.original_loan.reference_number} has been approved. Your new loan ##{new_loan.reference_number} has been created.",
        notification_type: "loan",
        source_type: "LoanRefinancing",
        source_id: refinancing.id
      )

      # Return the new loan
      new_loan
    end
  rescue => e
    Rails.logger.error("Error approving refinancing: #{e.message}")
    false
  end

  # Reject a refinancing application
  def reject_refinancing(refinancing, reason = nil)
    return false unless refinancing.pending?

    refinancing.update!(
      status: :rejected,
      rejection_reason: reason,
      rejected_at: Time.current
    )

    # Create a notification for the user
    @user.create_notification(
      title: "Loan Refinancing Rejected",
      content: "Your request to refinance loan ##{refinancing.original_loan.reference_number} has been rejected. #{reason}",
      notification_type: "loan",
      source_type: "LoanRefinancing",
      source_id: refinancing.id
    )

    true
  rescue => e
    Rails.logger.error("Error rejecting refinancing: #{e.message}")
    false
  end

  private

  # Get the credit score at the time the loan was created
  def loan_credit_score(loan)
    # Try to find a credit score from when the loan was created
    score_at_creation = @user.credit_scores
                             .where("calculated_at <= ?", loan.created_at)
                             .order(calculated_at: :desc)
                             .first

    # If no score found, use the loan's recorded score or a default
    score_at_creation&.score || loan.credit_score || 500
  end

  # Calculate new interest rate based on credit score
  def calculate_new_interest_rate(credit_score, loan_type)
    base_rate = case loan_type
                when "personal"
                  15.0
                when "business"
                  12.0
                when "education"
                  10.0
                when "emergency"
                  18.0
                when "microloan"
                  20.0
                when "agricultural"
                  9.0
                else
                  15.0
                end

    # Adjust rate based on credit score
    if credit_score >= 750
      base_rate - 5.0
    elsif credit_score >= 700
      base_rate - 3.5
    elsif credit_score >= 650
      base_rate - 2.0
    elsif credit_score >= 600
      base_rate - 1.0
    elsif credit_score >= 550
      base_rate - 0.5
    else
      base_rate
    end
  end

  # Calculate remaining interest on a loan
  def calculate_remaining_interest(loan, rate)
    # Simple interest calculation: principal * rate * time
    # Where time is in years
    principal = loan.amount_due

    # Safely calculate time in years
    time_in_years = 0
    if loan.due_date.present?
      time_in_years = (loan.due_date.to_date - Date.today).to_i / 365.0
    end

    # Calculate interest
    principal * (rate / 100) * time_in_years
  end

  # Calculate new term days for the refinanced loan
  def calculate_new_term_days(loan)
    # By default, use the remaining days from the original loan
    if loan.due_date.present?
      begin
        remaining_days = (loan.due_date.to_date - Date.today).to_i
        # Ensure at least 30 days
        return [remaining_days, 30].max
      rescue
        # If there's any error calculating the remaining days, default to 90 days
        return 90
      end
    else
      # If no due date, default to 90 days
      return 90
    end
  end
end
