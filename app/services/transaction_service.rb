class TransactionService
  attr_reader :transaction, :user, :ip_address, :user_agent, :errors

  # Initialize the service with a transaction and request context
  # @param transaction [Transaction] The transaction to process
  # @param user [User] The user initiating the transaction
  # @param ip_address [String] The IP address of the request
  # @param user_agent [String] The user agent of the request
  def initialize(transaction, user = nil, ip_address = nil, user_agent = nil)
    @transaction = transaction
    @user = user || transaction&.sender || transaction&.recipient
    @ip_address = ip_address
    @user_agent = user_agent
    @errors = []
  end

  # Process a transaction from start to finish
  # @param external_reference [String] External reference from payment provider
  # @param verification_data [Hash] Additional verification data if required
  # @return [Hash] Result of the transaction processing
  def process(external_reference: nil, verification_data: {})
    # Validate transaction exists
    unless transaction.present?
      return { success: false, message: "Transaction not found", code: :not_found }
    end

    # Validate transaction is in pending state
    unless transaction.status_pending?
      return {
        success: false,
        message: "Transaction cannot be processed in #{transaction.status} state",
        code: :invalid_state
      }
    end

    # Perform security check if user is present
    if user.present? && !transaction.security_check(user, ip_address, user_agent)
      return {
        success: false,
        message: "Transaction failed security checks",
        code: :security_check_failed,
        details: transaction.metadata.dig("security_check", "reasons")
      }
    end

    # Process based on transaction type
    case transaction.transaction_type
    when "deposit"
      process_deposit(external_reference, verification_data)
    when "withdrawal"
      process_withdrawal(external_reference, verification_data)
    when "transfer"
      process_transfer(verification_data)
    when "payment"
      process_payment(external_reference, verification_data)
    when "loan_disbursement"
      process_loan_disbursement
    when "loan_repayment"
      process_loan_repayment
    else
      { success: false, message: "Unsupported transaction type", code: :unsupported_type }
    end
  rescue StandardError => e
    # Log the error
    Rails.logger.error("Transaction processing error: #{e.message}\n#{e.backtrace.join("\n")}")

    # Mark transaction as failed
    transaction.fail!(reason: "System error: #{e.message}")

    # Return error result
    {
      success: false,
      message: "An error occurred while processing the transaction",
      code: :system_error,
      error: e.message
    }
  end

  private

  # Process a deposit transaction
  # @param external_reference [String] Reference from payment provider
  # @param verification_data [Hash] Additional verification data
  # @return [Hash] Result of the deposit processing
  def process_deposit(external_reference, verification_data)
    # Get the payment processor for this transaction
    processor = payment_processor_for(transaction.payment_method, transaction.provider)

    # Verify the deposit with the payment processor
    processor_result = processor.verify_deposit(
      amount: transaction.amount,
      currency: transaction.currency,
      reference: external_reference,
      metadata: transaction.metadata,
      verification_data: verification_data
    )

    if processor_result[:success]
      # Complete the transaction
      if transaction.complete!(external_reference: external_reference)
        # Send notification
        send_transaction_notification(transaction, :completed)

        # Return success result
        {
          success: true,
          message: "Deposit processed successfully",
          code: :success,
          transaction: transaction,
          reference: transaction.transaction_id
        }
      else
        # Transaction completion failed
        {
          success: false,
          message: "Failed to complete deposit",
          code: :completion_failed,
          transaction: transaction
        }
      end
    else
      # Payment processor verification failed
      transaction.fail!(reason: processor_result[:message])

      {
        success: false,
        message: processor_result[:message],
        code: :processor_verification_failed,
        transaction: transaction,
        processor_code: processor_result[:code]
      }
    end
  end

  # Process a withdrawal transaction
  # @param external_reference [String] Reference from payment provider
  # @param verification_data [Hash] Additional verification data
  # @return [Hash] Result of the withdrawal processing
  def process_withdrawal(external_reference, verification_data)
    # Check if user has sufficient balance
    unless transaction.source_wallet.can_debit?(transaction.amount)
      transaction.fail!(reason: "Insufficient funds")
      return {
        success: false,
        message: "Insufficient funds",
        code: :insufficient_funds,
        transaction: transaction
      }
    end

    # Get the payment processor for this transaction
    processor = payment_processor_for(transaction.payment_method, transaction.provider)

    # Process the withdrawal with the payment processor
    processor_result = processor.process_withdrawal(
      amount: transaction.amount,
      currency: transaction.currency,
      destination: transaction.metadata["destination_details"],
      reference: transaction.transaction_id,
      metadata: transaction.metadata,
      verification_data: verification_data
    )

    if processor_result[:success]
      # Complete the transaction
      if transaction.complete!(external_reference: processor_result[:provider_reference])
        # Send notification
        send_transaction_notification(transaction, :completed)

        # Return success result
        {
          success: true,
          message: "Withdrawal processed successfully",
          code: :success,
          transaction: transaction,
          reference: transaction.transaction_id,
          provider_reference: processor_result[:provider_reference]
        }
      else
        # Transaction completion failed - this is a critical error as money may have left the system
        # but the transaction wasn't marked as completed
        log_critical_error("Withdrawal processor succeeded but transaction completion failed", {
          transaction_id: transaction.id,
          external_reference: processor_result[:provider_reference]
        })

        {
          success: false,
          message: "Critical error: Withdrawal may have been processed but transaction update failed",
          code: :critical_completion_error,
          transaction: transaction,
          provider_reference: processor_result[:provider_reference]
        }
      end
    else
      # Payment processor failed
      transaction.fail!(reason: processor_result[:message])

      {
        success: false,
        message: processor_result[:message],
        code: :processor_failed,
        transaction: transaction,
        processor_code: processor_result[:code]
      }
    end
  end

  # Process a transfer transaction
  # @param verification_data [Hash] Additional verification data
  # @return [Hash] Result of the transfer processing
  def process_transfer(verification_data)
    # Check if user has sufficient balance
    unless transaction.source_wallet.can_debit?(transaction.amount)
      transaction.fail!(reason: "Insufficient funds")
      return {
        success: false,
        message: "Insufficient funds",
        code: :insufficient_funds,
        transaction: transaction
      }
    end

    # For transfers, we don't need a payment processor as it's internal
    # Just complete the transaction
    if transaction.complete!
      # Send notifications to both parties
      send_transaction_notification(transaction, :completed)
      send_transaction_notification(transaction, :received, transaction.recipient)

      # Return success result
      {
        success: true,
        message: "Transfer processed successfully",
        code: :success,
        transaction: transaction,
        reference: transaction.transaction_id
      }
    else
      # Transaction completion failed
      {
        success: false,
        message: "Failed to complete transfer",
        code: :completion_failed,
        transaction: transaction
      }
    end
  end

  # Process a payment transaction
  # @param external_reference [String] Reference from payment provider
  # @param verification_data [Hash] Additional verification data
  # @return [Hash] Result of the payment processing
  def process_payment(external_reference, verification_data)
    # Check if user has sufficient balance
    unless transaction.source_wallet.can_debit?(transaction.amount)
      transaction.fail!(reason: "Insufficient funds")
      return {
        success: false,
        message: "Insufficient funds",
        code: :insufficient_funds,
        transaction: transaction
      }
    end

    # For payments to merchants or services, we might need a payment processor
    # depending on the payment destination
    if transaction.metadata["requires_processor"]
      processor = payment_processor_for(transaction.payment_method, transaction.provider)

      processor_result = processor.process_payment(
        amount: transaction.amount,
        currency: transaction.currency,
        destination: transaction.metadata["destination_details"],
        reference: transaction.transaction_id,
        metadata: transaction.metadata,
        verification_data: verification_data
      )

      if processor_result[:success]
        external_ref = processor_result[:provider_reference]
      else
        transaction.fail!(reason: processor_result[:message])
        return {
          success: false,
          message: processor_result[:message],
          code: :processor_failed,
          transaction: transaction,
          processor_code: processor_result[:code]
        }
      end
    end

    # Complete the transaction
    if transaction.complete!(external_reference: external_reference)
      # Send notification
      send_transaction_notification(transaction, :completed)

      # Return success result
      {
        success: true,
        message: "Payment processed successfully",
        code: :success,
        transaction: transaction,
        reference: transaction.transaction_id
      }
    else
      # Transaction completion failed
      {
        success: false,
        message: "Failed to complete payment",
        code: :completion_failed,
        transaction: transaction
      }
    end
  end

  # Process a loan disbursement transaction
  # @return [Hash] Result of the loan disbursement processing
  def process_loan_disbursement
    begin
      # Add the amount to the wallet balance using the credit method
      wallet = transaction.destination_wallet
      result = wallet.credit(transaction.amount, transaction_id: transaction.transaction_id)

      if result
        # Mark transaction as successful
        if transaction.complete!
          # Send notification
          send_transaction_notification(transaction, :completed)

          {
            success: true,
            message: "Loan disbursement processed successfully",
            code: :success,
            transaction: transaction
          }
        else
          log_critical_error("Wallet credited but transaction completion failed", {
            transaction_id: transaction.id,
            wallet_id: wallet.id,
            amount: transaction.amount
          })

          {
            success: false,
            message: "Critical error: Wallet credited but transaction update failed",
            code: :critical_completion_error,
            transaction: transaction
          }
        end
      else
        transaction.fail!(reason: "Failed to credit wallet")
        {
          success: false,
          message: "Failed to credit wallet",
          code: :wallet_operation_failed,
          transaction: transaction
        }
      end
    rescue => e
      transaction.fail!(reason: e.message)
      {
        success: false,
        message: "Loan disbursement failed: #{e.message}",
        code: :system_error,
        transaction: transaction
      }
    end
  end

  # Process a loan repayment transaction
  # @return [Hash] Result of the loan repayment processing
  def process_loan_repayment
    begin
      wallet = transaction.source_wallet

      # Check if wallet has sufficient balance
      unless wallet.can_debit?(transaction.amount)
        transaction.fail!(reason: "Insufficient funds")
        return {
          success: false,
          message: "Insufficient funds",
          code: :insufficient_funds,
          transaction: transaction
        }
      end

      # Subtract the amount from the wallet balance using the debit method
      result = wallet.debit(transaction.amount, transaction_id: transaction.transaction_id)

      if result
        # Mark transaction as successful
        if transaction.complete!
          # Send notification
          send_transaction_notification(transaction, :completed)

          {
            success: true,
            message: "Loan repayment processed successfully",
            code: :success,
            transaction: transaction
          }
        else
          log_critical_error("Wallet debited but transaction completion failed", {
            transaction_id: transaction.id,
            wallet_id: wallet.id,
            amount: transaction.amount
          })

          {
            success: false,
            message: "Critical error: Wallet debited but transaction update failed",
            code: :critical_completion_error,
            transaction: transaction
          }
        end
      else
        transaction.fail!(reason: "Failed to debit wallet")
        {
          success: false,
          message: "Failed to debit wallet",
          code: :wallet_operation_failed,
          transaction: transaction
        }
      end
    rescue => e
      transaction.fail!(reason: e.message)
      {
        success: false,
        message: "Loan repayment failed: #{e.message}",
        code: :system_error,
        transaction: transaction
      }
    end
  end

  # Get the appropriate payment processor for the transaction
  # @param payment_method [Symbol, String] The payment method
  # @param provider [String] The payment provider
  # @return [Object] The payment processor instance
  def payment_processor_for(payment_method, provider)
    case payment_method.to_s
    when "mobile_money"
      case provider.to_s.downcase
      when "mtn"
        PaymentProcessors::MtnMobileMoneyProcessor.new
      when "vodafone"
        PaymentProcessors::VodafoneCashProcessor.new
      when "airtel", "tigo", "airteltigo"
        PaymentProcessors::AirtelTigoMoneyProcessor.new
      else
        PaymentProcessors::GenericMobileMoneyProcessor.new(provider)
      end
    when "bank_transfer"
      PaymentProcessors::BankTransferProcessor.new(provider)
    when "card_payment"
      PaymentProcessors::CardPaymentProcessor.new(provider)
    else
      # Default processor
      PaymentProcessors::GenericPaymentProcessor.new(payment_method, provider)
    end
  end

  # Send a notification about the transaction
  # @param transaction [Transaction] The transaction
  # @param event_type [Symbol] The event type (:completed, :failed, :received, etc.)
  # @param recipient [User] The notification recipient (defaults to transaction user)
  def send_transaction_notification(transaction, event_type, recipient = nil)
    # Determine the recipient
    notification_recipient = recipient || transaction.sender || transaction.recipient
    return unless notification_recipient

    # Determine notification details based on event type
    case event_type
    when :completed
      title = "Transaction Completed"
      message = case transaction.transaction_type
      when "deposit"
        "Your deposit of #{transaction.formatted_amount} has been completed."
      when "withdrawal"
        "Your withdrawal of #{transaction.formatted_amount} has been completed."
      when "transfer"
        "Your transfer of #{transaction.formatted_amount} to #{transaction.recipient_name} has been completed."
      when "payment"
        "Your payment of #{transaction.formatted_amount} has been completed."
      when "loan_disbursement"
        "Your loan of #{transaction.formatted_amount} has been disbursed to your wallet."
      when "loan_repayment"
        "Your loan repayment of #{transaction.formatted_amount} has been processed."
      end
    when :failed
      title = "Transaction Failed"
      message = "Your #{transaction.transaction_type} of #{transaction.formatted_amount} has failed."
      if transaction.metadata["failure_reason"].present?
        message += " Reason: #{transaction.metadata["failure_reason"]}"
      end
    when :received
      title = "Money Received"
      message = "You have received #{transaction.formatted_amount} from #{transaction.source_name}."
    end

    # Send the notification using the NotificationService if it exists
    if defined?(NotificationService)
      NotificationService.new(notification_recipient).send_notification(
        title: title,
        message: message,
        category: :transaction,
        data: {
          transaction_id: transaction.id,
          transaction_type: transaction.transaction_type,
          amount: transaction.amount,
          status: transaction.status
        }
      )
    else
      # Log the notification if service doesn't exist
      Rails.logger.info("NOTIFICATION to #{notification_recipient.id}: #{title} - #{message}")
    end
  end

  # Log a critical error that requires immediate attention
  # @param message [String] The error message
  # @param data [Hash] Additional data about the error
  def log_critical_error(message, data = {})
    Rails.logger.error("CRITICAL ERROR: #{message}")
    Rails.logger.error("Error data: #{data.inspect}")

    # In a production system, this would also:
    # 1. Send an alert to the operations team
    # 2. Create an incident in the monitoring system
    # 3. Possibly trigger an automated recovery process

    # For now, we'll just log it
    if defined?(ErrorReportingService)
      ErrorReportingService.report_critical_error(message, data)
    end
  end
end
