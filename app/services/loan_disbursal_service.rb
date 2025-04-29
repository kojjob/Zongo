class LoanDisbursalService
  def initialize(loan)
    @loan = loan
  end

  def disburse
    # Ensure loan is approved
    unless @loan.approved?
      return { success: false, message: "Loan must be approved before disbursement" }
    end

    # Create transaction to user's wallet
    # Check if wallet exists
    if @loan.wallet.nil?
      return { success: false, message: "User wallet not found" }
    end

    # Get the wallet object
    wallet = @loan.wallet

    transaction = Transaction.new(
      destination_wallet: wallet,
      transaction_type: "deposit",
      amount: @loan.amount,
      status: "pending",
      description: "Loan disbursement for #{@loan.reference_number}"
    )

    # Process the transaction
    if transaction.save
      transaction_service = TransactionService.new(transaction)
      transaction_result = transaction_service.process

      if transaction_result[:success]
        # Update loan status
        @loan.update(
          status: :active,
          disbursed_at: Time.current
        )

        # Notify user about disbursement
        UserNotificationService.new.notify_loan_disbursed(@loan) if defined?(UserNotificationService)

        { success: true, message: "Loan disbursed successfully" }
      else
        { success: false, message: transaction_result[:message] }
      end
    else
      { success: false, message: "Failed to create transaction" }
    end
  end
end
