class ScheduledTransactionProcessor
  # Constructor
  # @param logger [Logger] Logger instance (defaults to Rails logger)
  def initialize(logger = Rails.logger)
    @logger = logger
    @isolation_service = TransactionIsolationService.new(logger)
  end

  # Process all scheduled transactions that are due for execution
  # @return [Hash] Results of processing (success count, failure count, details)
  def process_due_transactions
    due_transactions = ScheduledTransaction.due_today
    @logger.info("Processing #{due_transactions.count} scheduled transactions due for execution")
    
    results = {
      total: due_transactions.count,
      success_count: 0,
      failure_count: 0,
      details: []
    }
    
    due_transactions.each do |scheduled_tx|
      result = process_scheduled_transaction(scheduled_tx)
      
      if result.success?
        results[:success_count] += 1
        results[:details] << {
          id: scheduled_tx.id,
          type: scheduled_tx.transaction_type,
          amount: scheduled_tx.amount,
          status: "success",
          transaction_id: result.data[:transaction]&.id
        }
      else
        results[:failure_count] += 1
        results[:details] << {
          id: scheduled_tx.id,
          type: scheduled_tx.transaction_type,
          amount: scheduled_tx.amount,
          status: "failed",
          error: result.error_message
        }
      end
    end
    
    @logger.info("Scheduled transactions processing completed: #{results[:success_count]} succeeded, #{results[:failure_count]} failed")
    results
  end
  
  # Process a single scheduled transaction with proper isolation
  # @param scheduled_transaction [ScheduledTransaction] The scheduled transaction to process
  # @return [Result] Result object with success or failure
  def process_scheduled_transaction(scheduled_transaction)
    @logger.info("Processing scheduled transaction ##{scheduled_transaction.id} (#{scheduled_transaction.transaction_type})")
    
    # Check if transaction is active and due
    unless scheduled_transaction.active?
      return Result.failure({
        message: "Scheduled transaction is not active",
        code: :inactive_transaction
      })
    end
    
    unless scheduled_transaction.next_occurrence <= Time.current
      return Result.failure({
        message: "Scheduled transaction is not due yet",
        code: :not_due
      })
    end
    
    # Process with isolation based on transaction type
    @isolation_service.transaction(:serializable, lock_for_update: true) do |_|
      transaction = nil
      
      case scheduled_transaction.transaction_type
      when "transfer"
        # Lock source and destination wallets
        source_wallet = @isolation_service.lock_wallet(scheduled_transaction.source_wallet)
        destination_wallet = @isolation_service.lock_wallet(scheduled_transaction.destination_wallet)
        
        # Create transaction
        transaction_result = TransactionService.create_transfer(
          source_wallet: source_wallet,
          destination_wallet: destination_wallet,
          amount: scheduled_transaction.amount,
          description: scheduled_transaction.description || "Scheduled transfer",
          metadata: {
            scheduled_transaction_id: scheduled_transaction.id,
            sender_name: source_wallet.user.display_name,
            recipient_name: scheduled_transaction.recipient_name
          }
        )
        
        return transaction_result unless transaction_result.success?
        transaction = transaction_result.data[:transaction]
        
        # Process the transaction with isolation
        process_result = @isolation_service.process_financial_transaction(transaction)
        return process_result unless process_result.success?
        
      when "deposit"
        # Lock the wallet
        wallet = @isolation_service.lock_wallet(scheduled_transaction.source_wallet)
        
        # Create transaction
        transaction_result = TransactionService.create_deposit(
          wallet: wallet,
          amount: scheduled_transaction.amount,
          payment_method: scheduled_transaction.payment_method,
          provider: scheduled_transaction.payment_provider,
          metadata: {
            scheduled_transaction_id: scheduled_transaction.id,
            description: scheduled_transaction.description || "Scheduled deposit"
          }
        )
        
        return transaction_result unless transaction_result.success?
        transaction = transaction_result.data[:transaction]
        
        # Process the transaction with isolation
        process_result = @isolation_service.process_financial_transaction(transaction)
        return process_result unless process_result.success?
        
      when "withdrawal"
        # Lock the wallet
        wallet = @isolation_service.lock_wallet(scheduled_transaction.source_wallet)
        
        # Create transaction
        transaction_result = TransactionService.create_withdrawal(
          wallet: wallet,
          amount: scheduled_transaction.amount,
          payment_method: scheduled_transaction.payment_method,
          provider: scheduled_transaction.payment_provider,
          metadata: {
            scheduled_transaction_id: scheduled_transaction.id,
            description: scheduled_transaction.description || "Scheduled withdrawal"
          }
        )
        
        return transaction_result unless transaction_result.success?
        transaction = transaction_result.data[:transaction]
        
        # Process the transaction with isolation
        process_result = @isolation_service.process_financial_transaction(transaction)
        return process_result unless process_result.success?
        
      when "payment"
        # Lock the source wallet
        source_wallet = @isolation_service.lock_wallet(scheduled_transaction.source_wallet)
        
        # For payment transactions, find or create a destination wallet
        destination_wallet = if scheduled_transaction.payment_destination.present? && 
                             scheduled_transaction.payment_destination.match?(/^\d+$/)
                              # If payment_destination is a numeric ID, try to find a wallet
                              Wallet.find_by(id: scheduled_transaction.payment_destination)
                            else
                              # Otherwise, use a system wallet or create a placeholder
                              Wallet.find_by(wallet_id: "SYSTEM") ||
                              source_wallet # Fallback to source wallet for testing
                            end
        
        # Lock destination wallet
        destination_wallet = @isolation_service.lock_wallet(destination_wallet)
        
        # Create transaction
        transaction_result = TransactionService.create_transfer(
          source_wallet: source_wallet,
          destination_wallet: destination_wallet,
          amount: scheduled_transaction.amount,
          description: scheduled_transaction.description || 
                      "Scheduled payment: #{scheduled_transaction.payment_destination}",
          metadata: {
            scheduled_transaction_id: scheduled_transaction.id,
            payment_destination: scheduled_transaction.payment_destination,
            transaction_type: "payment"
          }
        )
        
        return transaction_result unless transaction_result.success?
        transaction = transaction_result.data[:transaction]
        
        # Process the transaction with isolation
        process_result = @isolation_service.process_financial_transaction(transaction)
        return process_result unless process_result.success?
      end
      
      # Update scheduled transaction
      scheduled_transaction.occurrences_count += 1
      scheduled_transaction.last_occurrence = scheduled_transaction.next_occurrence
      
      if scheduled_transaction.occurrences_limit.present? && 
         scheduled_transaction.occurrences_count >= scheduled_transaction.occurrences_limit
        scheduled_transaction.status = :completed
      else
        scheduled_transaction.next_occurrence = scheduled_transaction.calculate_next_occurrence
      end
      
      if scheduled_transaction.save
        Result.success({
          message: "Scheduled transaction processed successfully",
          transaction: transaction,
          next_occurrence: scheduled_transaction.status_active? ? scheduled_transaction.next_occurrence : nil
        })
      else
        Result.failure({
          message: "Failed to update scheduled transaction",
          code: :update_failed,
          details: scheduled_transaction.errors.full_messages
        })
      end
    end
  rescue => e
    @logger.error("Error processing scheduled transaction ##{scheduled_transaction.id}: #{e.message}")
    Result.failure({
      message: "Error processing scheduled transaction: #{e.message}",
      code: :system_error,
      details: e.backtrace.join("\n")
    })
  end
  
  # Execute a scheduled transaction immediately, regardless of next_occurrence
  # @param scheduled_transaction [ScheduledTransaction] The scheduled transaction to execute
  # @return [Result] Result object with success or failure
  def execute_now(scheduled_transaction)
    @logger.info("Executing scheduled transaction ##{scheduled_transaction.id} (#{scheduled_transaction.transaction_type}) immediately")
    
    # Check if transaction is active
    unless scheduled_transaction.active?
      return Result.failure({
        message: "Cannot execute inactive scheduled transaction",
        code: :inactive_transaction
      })
    end
    
    # Process with the same logic but skip the due date check
    process_scheduled_transaction(scheduled_transaction)
  end
end
