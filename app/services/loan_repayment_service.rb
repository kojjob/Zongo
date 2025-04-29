class LoanRepaymentService
  def initialize(loan)
    @loan = loan
  end

  def process_repayment(amount)
    # Ensure loan is in a state that can accept repayments
    unless @loan.active? || @loan.disbursed?
      return { success: false, message: "Loan is not active" }
    end

    # Ensure amount is valid
    if amount <= 0 || amount > @loan.current_balance
      return { success: false, message: "Invalid repayment amount" }
    end

    # Create transaction from user's wallet
    # Check if wallet exists
    if @loan.wallet.nil?
      return { success: false, message: "User wallet not found" }
    end

    # Get the wallet object
    wallet = @loan.wallet

    transaction = Transaction.new(
      source_wallet: wallet,
      transaction_type: "payment",
      amount: amount,
      status: "pending",
      description: "Loan repayment for #{@loan.reference_number}",
      metadata: { loan_id: @loan.id }
    )

    # Process the transaction
    if transaction.save
      # Create loan repayment record
      repayment = @loan.loan_repayments.create!(
        transaction: transaction,
        amount: amount,
        status: :pending
      )

      # Process the transaction
      transaction_service = TransactionService.new(transaction)
      transaction_result = transaction_service.process

      if transaction_result[:success]
        # Update repayment record
        repayment.update!(
          status: :successful,
          principal_portion: calculate_principal_portion(amount),
          interest_portion: calculate_interest_portion(amount),
          fee_portion: calculate_fee_portion(amount),
          remaining_balance: @loan.current_balance - amount
        )

        # Update loan status if fully repaid
        if @loan.current_balance <= 0
          @loan.update(status: :completed)
        end

        { success: true, message: "Repayment successful" }
      else
        repayment.update(status: :failed)
        { success: false, message: transaction_result[:message] }
      end
    else
      { success: false, message: "Failed to create transaction" }
    end
  end

  private

  def calculate_principal_portion(amount)
    # Logic to determine how much of the payment goes to principal
    # For simplicity, we'll use a proportional approach
    total_due = @loan.amount_due
    principal_ratio = @loan.amount / total_due
    (amount * principal_ratio).round(2)
  end

  def calculate_interest_portion(amount)
    # Logic to determine how much of the payment goes to interest
    total_due = @loan.amount_due
    interest_amount = (total_due - @loan.amount - (@loan.processing_fee || 0))
    interest_ratio = interest_amount / total_due
    (amount * interest_ratio).round(2)
  end

  def calculate_fee_portion(amount)
    # Logic to determine how much of the payment goes to fees
    return 0 if @loan.processing_fee.nil? || @loan.processing_fee == 0

    total_due = @loan.amount_due
    fee_ratio = @loan.processing_fee / total_due
    (amount * fee_ratio).round(2)
  end
end
