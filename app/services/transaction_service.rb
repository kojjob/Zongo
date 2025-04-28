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
  # @return [Result] Result object with transaction processing outcome
  def process(external_reference: nil, verification_data: {})
    # Validate transaction exists
    unless transaction.present?
      return Result.failure({ message: "Transaction not found", code: :not_found })
    end

    # Validate transaction is in pending state
    unless transaction.status_pending?
      return Result.failure({
        message: "Transaction cannot be processed in #{transaction.status} state",
        code: :invalid_state
      })
    end

    # Perform security check if user is present
    if user.present? && !transaction.security_check(user, ip_address, user_agent)
      return Result.failure({
        message: "Transaction failed security checks",
        code: :security_check_failed,
        details: transaction.metadata.dig("security_check", "reasons")
      })
    end

    # Use the TransactionIsolationService to process the transaction with proper isolation
    isolation_service = TransactionIsolationService.new
    isolation_service.process_financial_transaction(transaction)
  rescue ActiveRecord::StaleObjectError => e
    # Handle optimistic locking failures
    log_error("Concurrent modification detected", e)
    transaction.fail!(reason: "Transaction failed due to concurrent modification")
    Result.failure({ message: "Transaction failed due to concurrent modification", code: :concurrency_error })
  rescue ActiveRecord::StatementInvalid => e
    # Handle database-related errors
    log_error("Database error during transaction processing", e)
    transaction.fail!(reason: "Transaction failed due to database error")
    Result.failure({ message: "Transaction failed due to database error", code: :database_error })
  rescue StandardError => e
    # Log the error
    log_error("Transaction processing error", e)

    # Mark transaction as failed
    transaction.fail!(reason: "System error: #{e.message}")

    # Return error result
    Result.failure({
      message: "An error occurred while processing the transaction",
      code: :system_error,
      details: e.message
    })
  end

  # Create a new transfer transaction
  # @param source_wallet [Wallet] The source wallet
  # @param destination_wallet [Wallet] The destination wallet
  # @param amount [Decimal] The amount to transfer
  # @param description [String] The transaction description
  # @param metadata [Hash] Additional transaction metadata
  # @return [Result] Result object with the created transaction or error
  def self.create_transfer(source_wallet:, destination_wallet:, amount:, description: nil, metadata: {})
    # Use the TransactionIsolationService for proper isolation
    isolation_service = TransactionIsolationService.new
    
    # Execute within a transaction with proper isolation
    isolation_service.transaction(:serializable) do |_lock_for_update|
      # Validate wallets and amount
      return Result.failure({ message: "Source wallet is required", code: :missing_source }) unless source_wallet
      return Result.failure({ message: "Destination wallet is required", code: :missing_destination }) unless destination_wallet
      return Result.failure({ message: "Amount must be greater than zero", code: :invalid_amount }) unless amount.to_f > 0

      # Check if wallets are different
      if source_wallet.id == destination_wallet.id
        return Result.failure({ message: "Source and destination wallets cannot be the same", code: :same_wallet })
      end

      # Check if source wallet is active
      unless source_wallet.active?
        return Result.failure({ message: "Source wallet is not active", code: :inactive_source })
      end

      # Check if destination wallet is active
      unless destination_wallet.active?
        return Result.failure({ message: "Destination wallet is not active", code: :inactive_destination })
      end
      
      # Check if user has sufficient balance - lock the wallet first
      locked_source = isolation_service.lock_wallet(source_wallet)
      
      # Check balance after locking
      unless locked_source.can_debit?(amount)
        return Result.failure({ message: "Insufficient funds", code: :insufficient_funds })
      end

      # Create the transaction
      transaction = Transaction.create_transfer(
        source_wallet: locked_source,
        destination_wallet: destination_wallet,
        amount: amount,
        description: description,
        metadata: metadata
      )

      if transaction.persisted?
        Result.success(data: { transaction: transaction })
      else
        Result.failure({ 
          message: "Failed to create transfer transaction", 
          code: :creation_failed,
          details: transaction.errors.full_messages 
        })
      end
    end
  rescue => e
    log_class_error("Error creating transfer transaction", e)
    Result.failure({ message: "Error creating transfer transaction", code: :system_error, details: e.message })
  end

  # Create a new deposit transaction
  # @param wallet [Wallet] The destination wallet
  # @param amount [Decimal] The amount to deposit
  # @param payment_method [Symbol] The payment method
  # @param provider [String] The payment provider
  # @param metadata [Hash] Additional transaction metadata
  # @return [Result] Result object with the created transaction or error
  def self.create_deposit(wallet:, amount:, payment_method:, provider:, metadata: {})
    # Use the TransactionIsolationService for proper isolation
    isolation_service = TransactionIsolationService.new
    
    # Execute within a transaction with proper isolation
    isolation_service.transaction(:serializable) do |_lock_for_update|
      # Validate wallet and amount
      return Result.failure({ message: "Wallet is required", code: :missing_wallet }) unless wallet
      return Result.failure({ message: "Amount must be greater than zero", code: :invalid_amount }) unless amount.to_f > 0
      return Result.failure({ message: "Payment method is required", code: :missing_payment_method }) unless payment_method
      return Result.failure({ message: "Provider is required", code: :missing_provider }) unless provider

      # Check if wallet is active
      unless wallet.active?
        return Result.failure({ message: "Wallet is not active", code: :inactive_wallet })
      end

      # Create the transaction
      transaction = Transaction.create_deposit(
        wallet: wallet,
        amount: amount,
        payment_method: payment_method,
        provider: provider,
        metadata: metadata
      )

      if transaction.persisted?
        Result.success(data: { transaction: transaction })
      else
        Result.failure({ 
          message: "Failed to create deposit transaction", 
          code: :creation_failed,
          details: transaction.errors.full_messages 
        })
      end
    end
  rescue => e
    log_class_error("Error creating deposit transaction", e)
    Result.failure({ message: "Error creating deposit transaction", code: :system_error, details: e.message })
  end

  # Create a new withdrawal transaction
  # @param wallet [Wallet] The source wallet
  # @param amount [Decimal] The amount to withdraw
  # @param payment_method [Symbol] The payment method
  # @param provider [String] The payment provider
  # @param metadata [Hash] Additional transaction metadata
  # @return [Result] Result object with the created transaction or error
  def self.create_withdrawal(wallet:, amount:, payment_method:, provider:, metadata: {})
    # Use the TransactionIsolationService for proper isolation
    isolation_service = TransactionIsolationService.new
    
    # Execute within a transaction with proper isolation
    isolation_service.transaction(:serializable) do |_lock_for_update|
      # Validate wallet and amount
      return Result.failure({ message: "Wallet is required", code: :missing_wallet }) unless wallet
      return Result.failure({ message: "Amount must be greater than zero", code: :invalid_amount }) unless amount.to_f > 0
      return Result.failure({ message: "Payment method is required", code: :missing_payment_method }) unless payment_method
      return Result.failure({ message: "Provider is required", code: :missing_provider }) unless provider

      # Check if wallet is active
      unless wallet.active?
        return Result.failure({ message: "Wallet is not active", code: :inactive_wallet })
      end

      # Check if wallet has sufficient balance - lock the wallet first
      locked_wallet = isolation_service.lock_wallet(wallet)
      
      # Check balance after locking
      unless locked_wallet.can_debit?(amount)
        return Result.failure({ message: "Insufficient funds", code: :insufficient_funds })
      end

      # Create the transaction
      transaction = Transaction.create_withdrawal(
        wallet: locked_wallet,
        amount: amount,
        payment_method: payment_method,
        provider: provider,
        metadata: metadata
      )

      if transaction.persisted?
        Result.success(data: { transaction: transaction })
      else
        Result.failure({ 
          message: "Failed to create withdrawal transaction", 
          code: :creation_failed,
          details: transaction.errors.full_messages 
        })
      end
    end
  rescue => e
    log_class_error("Error creating withdrawal transaction", e)
    Result.failure({ message: "Error creating withdrawal transaction", code: :system_error, details: e.message })
  end

  # Get a transaction by its ID
  # @param id [String] The transaction ID
  # @return [Result] Result object with the transaction or error
  def self.find_by_id(id)
    transaction = Transaction.find_by(id: id)

    if transaction
      Result.success(data: { transaction: transaction })
    else
      Result.failure(error: { message: "Transaction not found", code: :not_found })
    end
  rescue StandardError => e
    log_class_error("Error finding transaction", e)
    Result.failure(error: { message: "Error finding transaction", code: :system_error, details: e.message })
  end

  # Get a transaction by its transaction_id (reference number)
  # @param transaction_id [String] The transaction_id
  # @return [Result] Result object with the transaction or error
  def self.find_by_transaction_id(transaction_id)
    transaction = Transaction.find_by(transaction_id: transaction_id)

    if transaction
      Result.success(data: { transaction: transaction })
    else
      Result.failure(error: { message: "Transaction not found", code: :not_found })
    end
  rescue StandardError => e
    log_class_error("Error finding transaction by transaction_id", e)
    Result.failure(error: { message: "Error finding transaction", code: :system_error, details: e.message })
  end

  private

  # Process a deposit transaction
  # @param external_reference [String] Reference from payment provider
  # @param verification_data [Hash] Additional verification data
  # @return [Result] Result of the deposit processing
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
        Result.success(data: {
          message: "Deposit processed successfully",
          transaction: transaction,
          reference: transaction.transaction_id
        })
      else
        # Transaction completion failed
        Result.failure(error: {
          message: "Failed to complete deposit",
          code: :completion_failed,
          transaction: transaction
        })
      end
    else
      # Payment processor verification failed
      transaction.fail!(reason: processor_result[:message])

      Result.failure(error: {
        message: processor_result[:message],
        code: :processor_verification_failed,
        transaction: transaction,
        processor_code: processor_result[:code]
      })
    end
  end

  # Process a withdrawal transaction
  # @param external_reference [String] Reference from payment provider
  # @param verification_data [Hash] Additional verification data
  # @return [Result] Result of the withdrawal processing
  def process_withdrawal(external_reference, verification_data)
    # Reload and lock the wallet to prevent race conditions
    source_wallet = transaction.source_wallet.reload.lock!

    # Check if user has sufficient balance
    unless source_wallet.can_debit?(transaction.amount)
      transaction.fail!(reason: "Insufficient funds")
      return Result.failure(error: {
        message: "Insufficient funds",
        code: :insufficient_funds,
        transaction: transaction
      })
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
        Result.success(data: {
          message: "Withdrawal processed successfully",
          transaction: transaction,
          reference: transaction.transaction_id,
          provider_reference: processor_result[:provider_reference]
        })
      else
        # Transaction completion failed - this is a critical error as money may have left the system
        # but the transaction wasn't marked as completed
        log_critical_error("Withdrawal processor succeeded but transaction completion failed", {
          transaction_id: transaction.id,
          external_reference: processor_result[:provider_reference]
        })

        Result.failure(error: {
          message: "Critical error: Withdrawal may have been processed but transaction update failed",
          code: :critical_completion_error,
          transaction: transaction,
          provider_reference: processor_result[:provider_reference]
        })
      end
    else
      # Payment processor failed
      transaction.fail!(reason: processor_result[:message])

      Result.failure(error: {
        message: processor_result[:message],
        code: :processor_failed,
        transaction: transaction,
        processor_code: processor_result[:code]
      })
    end
  end

  # Process a transfer transaction
  # @param verification_data [Hash] Additional verification data
  # @return [Result] Result of the transfer processing
  def process_transfer(verification_data)
    # Reload and lock both wallets to prevent race conditions
    source_wallet = transaction.source_wallet.reload.lock!
    destination_wallet = transaction.destination_wallet.reload.lock!

    # Check if user has sufficient balance
    unless source_wallet.can_debit?(transaction.amount)
      transaction.fail!(reason: "Insufficient funds")
      return Result.failure(error: {
        message: "Insufficient funds",
        code: :insufficient_funds,
        transaction: transaction
      })
    end

    # For transfers, we don't need a payment processor as it's internal
    # Just complete the transaction
    if transaction.complete!
      # Send notifications to both parties
      send_transaction_notification(transaction, :completed)
      send_transaction_notification(transaction, :received, transaction.recipient)

      # Return success result
      Result.success(data: {
        message: "Transfer processed successfully",
        transaction: transaction,
        reference: transaction.transaction_id
      })
    else
      # Transaction completion failed
      Result.failure(error: {
        message: "Failed to complete transfer",
        code: :completion_failed,
        transaction: transaction
      })
    end
  end

  # Process a payment transaction
  # @param external_reference [String] Reference from payment provider
  # @param verification_data [Hash] Additional verification data
  # @return [Result] Result of the payment processing
  def process_payment(external_reference, verification_data)
    # Reload and lock the wallet to prevent race conditions
    source_wallet = transaction.source_wallet.reload.lock!

    # Check if user has sufficient balance
    unless source_wallet.can_debit?(transaction.amount)
      transaction.fail!(reason: "Insufficient funds")
      return Result.failure(error: {
        message: "Insufficient funds",
        code: :insufficient_funds,
        transaction: transaction
      })
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
        return Result.failure(error: {
          message: processor_result[:message],
          code: :processor_failed,
          transaction: transaction,
          processor_code: processor_result[:code]
        })
      end
    end

    # Complete the transaction
    if transaction.complete!(external_reference: external_reference)
      # Send notification
      send_transaction_notification(transaction, :completed)

      # Return success result
      Result.success(data: {
        message: "Payment processed successfully",
        transaction: transaction,
        reference: transaction.transaction_id
      })
    else
      # Transaction completion failed
      Result.failure(error: {
        message: "Failed to complete payment",
        code: :completion_failed,
        transaction: transaction
      })
    end
  end

  # Process a loan disbursement transaction
  # @return [Result] Result of the loan disbursement processing
  def process_loan_disbursement
    begin
      # Reload and lock the wallet to prevent race conditions
      wallet = transaction.destination_wallet.reload.lock!
      
      # Add the amount to the wallet balance using the credit method
      result = wallet.credit(transaction.amount, transaction_id: transaction.transaction_id)

      if result
        # Mark transaction as successful
        if transaction.complete!
          # Send notification
          send_transaction_notification(transaction, :completed)

          Result.success(data: {
            message: "Loan disbursement processed successfully",
            transaction: transaction
          })
        else
          log_critical_error("Wallet credited but transaction completion failed", {
            transaction_id: transaction.id,
            wallet_id: wallet.id,
            amount: transaction.amount
          })

          Result.failure(error: {
            message: "Critical error: Wallet credited but transaction update failed",
            code: :critical_completion_error,
            transaction: transaction
          })
        end
      else
        transaction.fail!(reason: "Failed to credit wallet")
        Result.failure(error: {
          message: "Failed to credit wallet",
          code: :wallet_operation_failed,
          transaction: transaction
        })
      end
    rescue => e
      transaction.fail!(reason: e.message)
      Result.failure(error: {
        message: "Loan disbursement failed: #{e.message}",
        code: :system_error,
        transaction: transaction
      })
    end
  end

  # Process a loan repayment transaction
  # @return [Result] Result of the loan repayment processing
  def process_loan_repayment
    begin
      # Reload and lock the wallet to prevent race conditions
      wallet = transaction.source_wallet.reload.lock!

      # Check if wallet has sufficient balance
      unless wallet.can_debit?(transaction.amount)
        transaction.fail!(reason: "Insufficient funds")
        return Result.failure(error: {
          message: "Insufficient funds",
          code: :insufficient_funds,
          transaction: transaction
        })
      end

      # Subtract the amount from the wallet balance using the debit method
      result = wallet.debit(transaction.amount, transaction_id: transaction.transaction_id)

      if result
        # Mark transaction as successful
        if transaction.complete!
          # Send notification
          send_transaction_notification(transaction, :completed)

          Result.success(data: {
            message: "Loan repayment processed successfully",
            transaction: transaction
          })
        else
          log_critical_error("Wallet debited but transaction completion failed", {
            transaction_id: transaction.id,
            wallet_id: wallet.id,
            amount: transaction.amount
          })

          Result.failure(error: {
            message: "Critical error: Wallet debited but transaction update failed",
            code: :critical_completion_error,
            transaction: transaction
          })
        end
      else
        transaction.fail!(reason: "Failed to debit wallet")
        Result.failure(error: {
          message: "Failed to debit wallet",
          code: :wallet_operation_failed,
          transaction: transaction
        })
      end
    rescue => e
      transaction.fail!(reason: e.message)
      Result.failure(error: {
        message: "Loan repayment failed: #{e.message}",
        code: :system_error,
        transaction: transaction
      })
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

    # Create security log for the event
    if defined?(SecurityLog) && user.present?
      SecurityLog.log_event(
        user,
        :critical_transaction_error,
        severity: :critical,
        details: {
          message: message,
          transaction_id: transaction&.id,
          data: data
        },
        loggable: transaction
      )
    end

    # In a production system, this would also:
    # 1. Send an alert to the operations team
    # 2. Create an incident in the monitoring system
    # 3. Possibly trigger an automated recovery process

    # For now, we'll just log it
    if defined?(ErrorReportingService)
      ErrorReportingService.report_critical_error(message, data)
    end
  end

  # Log a standard error
  # @param message [String] The error message
  # @param exception [Exception] The exception object
  def log_error(message, exception)
    Rails.logger.error("#{message}: #{exception.message}")
    Rails.logger.error(exception.backtrace.join("\n")) if exception.backtrace

    # Create security log for the event if related to a user
    if defined?(SecurityLog) && user.present?
      SecurityLog.log_event(
        user,
        :transaction_error,
        severity: :warning,
        details: {
          message: message,
          error: exception.message,
          transaction_id: transaction&.id
        },
        loggable: transaction
      )
    end

    # Report error to monitoring service if available
    if defined?(ErrorReportingService)
      ErrorReportingService.report_error(message, exception)
    end
  end

  # Log a class-level error (for static methods)
  # @param message [String] The error message
  # @param exception [Exception] The exception object
  def self.log_class_error(message, exception)
    Rails.logger.error("#{message}: #{exception.message}")
    Rails.logger.error(exception.backtrace.join("\n")) if exception.backtrace

    # Report error to monitoring service if available
    if defined?(ErrorReportingService)
      ErrorReportingService.report_error(message, exception)
    end
  end
end
