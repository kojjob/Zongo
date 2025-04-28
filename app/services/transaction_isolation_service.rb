class TransactionIsolationService
  # Constants for isolation levels
  ISOLATION_LEVELS = {
    read_uncommitted: 'READ UNCOMMITTED',
    read_committed: 'READ COMMITTED',
    repeatable_read: 'REPEATABLE READ',
    serializable: 'SERIALIZABLE'
  }.freeze

  # Maximum number of retries for deadlock situations
  MAX_RETRIES = 3

  # Default retry delay in seconds
  DEFAULT_RETRY_DELAY = 0.5

  # Constructor
  # @param logger [Logger] Logger instance (defaults to Rails logger)
  def initialize(logger = Rails.logger)
    @logger = logger
  end

  # Execute a block within a transaction with specified isolation level
  # @param isolation_level [Symbol] The isolation level to use
  # @param options [Hash] Additional options for the transaction
  # @option options [Integer] :retry_count Maximum number of retries (default: MAX_RETRIES)
  # @option options [Float] :retry_delay Delay between retries in seconds (default: DEFAULT_RETRY_DELAY)
  # @option options [Boolean] :lock_for_update Whether to use FOR UPDATE locking (default: false)
  # @yield The block to execute within the transaction
  # @return [Result] Result object with success or failure
  def transaction(isolation_level = :serializable, options = {})
    retry_count = options[:retry_count] || MAX_RETRIES
    retry_delay = options[:retry_delay] || DEFAULT_RETRY_DELAY
    lock_for_update = options[:lock_for_update] || false

    attempts = 0

    begin
      attempts += 1

      result = ActiveRecord::Base.transaction(isolation: isolation_level) do
        # Yield to the provided block
        yield(lock_for_update)
      end

      # If we get here, the transaction was successful
      return Result.success(data: result)
    rescue ActiveRecord::Deadlock, ActiveRecord::LockWaitTimeout => e
      # Handle deadlock and lock timeout situations with retries
      if attempts <= retry_count
        @logger.warn("Deadlock or lock timeout detected (attempt #{attempts}/#{retry_count}): #{e.message}")
        sleep(retry_delay * attempts) # Exponential backoff
        retry
      else
        @logger.error("Transaction failed after #{retry_count} attempts due to deadlock or lock timeout: #{e.message}")
        return Result.failure(ConcurrencyError.new("Transaction failed due to database contention after #{retry_count} attempts", e))
      end
    rescue ActiveRecord::SerializationFailure => e
      # Handle serialization failures (conflicts in serializable isolation)
      if attempts <= retry_count
        @logger.warn("Serialization failure detected (attempt #{attempts}/#{retry_count}): #{e.message}")
        sleep(retry_delay)
        retry
      else
        @logger.error("Transaction failed after #{retry_count} attempts due to serialization failure: #{e.message}")
        return Result.failure(ConcurrencyError.new("Transaction failed due to serialization conflicts after #{retry_count} attempts", e))
      end
    rescue ActiveRecord::StaleObjectError => e
      # Handle stale object errors (optimistic locking failures)
      @logger.error("Optimistic locking failure: #{e.message}")
      return Result.failure(ConcurrencyError.new("Concurrent modification detected", e))
    rescue ActiveRecord::StatementInvalid => e
      # Handle other SQL related errors
      @logger.error("SQL error in transaction: #{e.message}")
      return Result.failure(ServiceError.new("Database error during transaction", :database_error, e))
    rescue StandardError => e
      # Handle other errors
      @logger.error("Error in transaction: #{e.message}")
      return Result.failure(ServiceError.new("An error occurred during transaction processing", :system_error, e))
    end
  end

  # Lock a wallet for update
  # @param wallet [Wallet] The wallet to lock
  # @return [Wallet] The locked wallet
  def lock_wallet(wallet)
    Wallet.where(id: wallet.id).lock("FOR UPDATE NOWAIT").first || wallet.reload.lock!
  end

  # Lock multiple wallets for update in a consistent order to prevent deadlocks
  # @param wallets [Array<Wallet>] The wallets to lock
  # @return [Array<Wallet>] The locked wallets
  def lock_wallets(*wallets)
    # Sort wallets by ID to ensure consistent locking order
    wallet_ids = wallets.map(&:id).sort
    
    # Lock wallets in order
    locked_wallets = []
    wallet_ids.each do |id|
      locked_wallet = Wallet.where(id: id).lock("FOR UPDATE NOWAIT").first
      locked_wallets << (locked_wallet || Wallet.find(id).lock!)
    end
    
    locked_wallets
  end
  
  # Execute a balance update operation with proper isolation
  # @param wallet [Wallet] The wallet to update
  # @param amount [Decimal] The amount to add (positive) or subtract (negative)
  # @param transaction_id [String] The transaction ID
  # @return [Result] Result object with success or failure
  def update_wallet_balance(wallet, amount, transaction_id = nil)
    transaction(:serializable, lock_for_update: true) do |should_lock|
      # Lock the wallet for update
      locked_wallet = should_lock ? lock_wallet(wallet) : wallet
      
      # Check for negative balance if deducting
      if amount.negative? && (locked_wallet.balance + amount) < 0
        raise InsufficientFundsError.new("Insufficient funds", { 
          available: locked_wallet.balance, 
          requested: amount.abs 
        })
      end
      
      # Update the balance using raw SQL for maximum isolation
      updated_rows = ActiveRecord::Base.connection.execute(<<~SQL)
        UPDATE wallets 
        SET balance = balance + #{ActiveRecord::Base.connection.quote(amount)},
            last_transaction_at = #{ActiveRecord::Base.connection.quote(Time.current)}
        WHERE id = #{ActiveRecord::Base.connection.quote(locked_wallet.id)}
        AND balance + #{ActiveRecord::Base.connection.quote(amount)} >= 0
      SQL
      
      # Verify the update succeeded
      if updated_rows == 0
        raise ActiveRecord::StaleObjectError.new(locked_wallet, "update_wallet_balance")
      end
      
      # Reload the wallet to get the updated balance
      locked_wallet.reload
      
      # Log the operation
      @logger.info("Wallet #{locked_wallet.wallet_id} balance updated: #{amount > 0 ? 'credited' : 'debited'} #{amount.abs} (Transaction: #{transaction_id || 'N/A'})")
      
      # Return the updated wallet
      locked_wallet
    end
  end
  
  # Execute a transfer between two wallets with proper isolation
  # @param source_wallet [Wallet] The source wallet
  # @param destination_wallet [Wallet] The destination wallet
  # @param amount [Decimal] The amount to transfer
  # @param transaction_id [String] The transaction ID
  # @return [Result] Result object with success or failure
  def transfer_between_wallets(source_wallet, destination_wallet, amount, transaction_id = nil)
    # Validate amount
    return Result.failure(ValidationError.new("Amount must be positive")) unless amount.positive?
    
    # Verify that wallets are different
    if source_wallet.id == destination_wallet.id
      return Result.failure(ValidationError.new("Source and destination wallets must be different"))
    end
    
    transaction(:serializable, lock_for_update: true) do |should_lock|
      if should_lock
        # Lock both wallets in a consistent order to prevent deadlocks
        locked_wallets = lock_wallets(source_wallet, destination_wallet)
        locked_source = locked_wallets.find { |w| w.id == source_wallet.id }
        locked_destination = locked_wallets.find { |w| w.id == destination_wallet.id }
      else
        locked_source = source_wallet
        locked_destination = destination_wallet
      end
      
      # Check if source has sufficient balance
      if locked_source.balance < amount
        raise InsufficientFundsError.new("Insufficient funds", { 
          available: locked_source.balance, 
          requested: amount 
        })
      end
      
      # Perform the debit operation
      ActiveRecord::Base.connection.execute(<<~SQL)
        UPDATE wallets 
        SET balance = balance - #{ActiveRecord::Base.connection.quote(amount)},
            last_transaction_at = #{ActiveRecord::Base.connection.quote(Time.current)}
        WHERE id = #{ActiveRecord::Base.connection.quote(locked_source.id)}
        AND balance >= #{ActiveRecord::Base.connection.quote(amount)}
      SQL
      
      # Perform the credit operation
      ActiveRecord::Base.connection.execute(<<~SQL)
        UPDATE wallets 
        SET balance = balance + #{ActiveRecord::Base.connection.quote(amount)},
            last_transaction_at = #{ActiveRecord::Base.connection.quote(Time.current)}
        WHERE id = #{ActiveRecord::Base.connection.quote(locked_destination.id)}
      SQL
      
      # Reload both wallets to get the updated balances
      locked_source.reload
      locked_destination.reload
      
      # Log the operation
      @logger.info("Transfer completed: #{amount} from wallet #{locked_source.wallet_id} to #{locked_destination.wallet_id} (Transaction: #{transaction_id || 'N/A'})")
      
      # Return the updated wallets
      {
        source_wallet: locked_source,
        destination_wallet: locked_destination,
        amount: amount
      }
    end
  end
  
  # Process a complete financial transaction with proper isolation
  # @param transaction [Transaction] The transaction to process
  # @return [Result] Result object with success or failure
  def process_financial_transaction(transaction)
    # Validate transaction state
    unless transaction.status_pending?
      return Result.failure(BusinessRuleError.new(
        "Transaction cannot be processed in #{transaction.status} state",
        :invalid_transaction_state
      ))
    end
    
    # Process based on transaction type
    case transaction.transaction_type
    when "deposit"
      process_deposit(transaction)
    when "withdrawal"
      process_withdrawal(transaction)
    when "transfer"
      process_transfer(transaction)
    when "payment"
      process_payment(transaction)
    else
      Result.failure(ValidationError.new("Unsupported transaction type: #{transaction.transaction_type}"))
    end
  end
  
  private
  
  # Process a deposit transaction
  # @param transaction [Transaction] The deposit transaction
  # @return [Result] Result object with success or failure
  def process_deposit(transaction)
    # Get destination wallet
    destination_wallet = transaction.destination_wallet
    return Result.failure(ValidationError.new("Destination wallet not found")) unless destination_wallet
    
    # Credit the destination wallet
    result = update_wallet_balance(destination_wallet, transaction.amount, transaction.transaction_id)
    return result unless result.success?
    
    # Update the transaction status
    if transaction.update(status: :completed, completed_at: Time.current)
      Result.success(data: {
        message: "Deposit processed successfully",
        transaction: transaction,
        wallet: result.data
      })
    else
      Result.failure(ServiceError.new("Failed to update transaction status"))
    end
  end
  
  # Process a withdrawal transaction
  # @param transaction [Transaction] The withdrawal transaction
  # @return [Result] Result object with success or failure
  def process_withdrawal(transaction)
    # Get source wallet
    source_wallet = transaction.source_wallet
    return Result.failure(ValidationError.new("Source wallet not found")) unless source_wallet
    
    # Debit the source wallet
    result = update_wallet_balance(source_wallet, -transaction.amount, transaction.transaction_id)
    return result unless result.success?
    
    # Update the transaction status
    if transaction.update(status: :completed, completed_at: Time.current)
      Result.success(data: {
        message: "Withdrawal processed successfully",
        transaction: transaction,
        wallet: result.data
      })
    else
      Result.failure(ServiceError.new("Failed to update transaction status"))
    end
  end
  
  # Process a transfer transaction
  # @param transaction [Transaction] The transfer transaction
  # @return [Result] Result object with success or failure
  def process_transfer(transaction)
    # Get source and destination wallets
    source_wallet = transaction.source_wallet
    destination_wallet = transaction.destination_wallet
    
    # Validate wallets
    return Result.failure(ValidationError.new("Source wallet not found")) unless source_wallet
    return Result.failure(ValidationError.new("Destination wallet not found")) unless destination_wallet
    
    # Transfer between wallets
    result = transfer_between_wallets(
      source_wallet,
      destination_wallet,
      transaction.amount,
      transaction.transaction_id
    )
    return result unless result.success?
    
    # Update the transaction status
    if transaction.update(status: :completed, completed_at: Time.current)
      Result.success(data: {
        message: "Transfer processed successfully",
        transaction: transaction,
        source_wallet: result.data[:source_wallet],
        destination_wallet: result.data[:destination_wallet]
      })
    else
      Result.failure(ServiceError.new("Failed to update transaction status"))
    end
  end
  
  # Process a payment transaction
  # @param transaction [Transaction] The payment transaction
  # @return [Result] Result object with success or failure
  def process_payment(transaction)
    # Payments are handled similar to transfers
    process_transfer(transaction)
  end
end
