class WalletService
  attr_reader :wallet, :user, :errors, :isolation_service

  def initialize(wallet_or_user)
    if wallet_or_user.is_a?(Wallet)
      @wallet = wallet_or_user
      @user = wallet_or_user.user
    elsif wallet_or_user.is_a?(User)
      @user = wallet_or_user
      @wallet = wallet_or_user.wallet
    else
      raise ArgumentError, "Must provide a Wallet or User"
    end
    @errors = []
    @isolation_service = TransactionIsolationService.new
  end

  # Deposit funds into the wallet
  # @param amount [Decimal] The amount to deposit
  # @param payment_method [Symbol, String] The payment method used
  # @param provider [String] The payment provider
  # @param metadata [Hash] Additional information about the transaction
  # @return [Result] Success result with transaction details or failure result
  def deposit(amount, payment_method:, provider:, metadata: {})
    # Validate inputs
    return Result.failure({ message: "Amount must be greater than zero", code: :invalid_amount }) unless amount.to_f > 0
    return Result.failure({ message: "Payment method is required", code: :missing_payment_method }) if payment_method.blank?
    return Result.failure({ message: "Provider is required", code: :missing_provider }) if provider.blank?
    
    # Validate wallet status
    return Result.failure({ message: "Wallet is inactive", code: :inactive_wallet }) unless wallet.active?

    # Create transaction via TransactionService
    result = TransactionService.create_deposit(
      wallet: wallet,
      amount: amount,
      payment_method: payment_method,
      provider: provider,
      metadata: metadata
    )

    # Return the result directly as it's already a Result object
    result
  end

  # Withdraw funds from the wallet
  # @param amount [Decimal] The amount to withdraw
  # @param payment_method [Symbol, String] The payment method to use
  # @param provider [String] The payment provider
  # @param metadata [Hash] Additional information about the transaction
  # @return [Result] Success result with transaction details or failure result
  def withdraw(amount, payment_method:, provider:, metadata: {})
    # Validate inputs
    return Result.failure({ message: "Amount must be greater than zero", code: :invalid_amount }) unless amount.to_f > 0
    return Result.failure({ message: "Payment method is required", code: :missing_payment_method }) if payment_method.blank?
    return Result.failure({ message: "Provider is required", code: :missing_provider }) if provider.blank?
    
    # Validate wallet status
    return Result.failure({ message: "Wallet is inactive", code: :inactive_wallet }) unless wallet.active?
    
    # Check balance
    unless wallet.can_debit?(amount)
      return Result.failure({ 
        message: "Insufficient funds", 
        code: :insufficient_funds,
        details: { available: wallet.balance, requested: amount }
      })
    end

    # Create transaction via TransactionService
    result = TransactionService.create_withdrawal(
      wallet: wallet,
      amount: amount,
      payment_method: payment_method,
      provider: provider,
      metadata: metadata
    )

    # Return the result directly
    result
  end

  # Transfer funds to another wallet
  # @param destination_wallet [Wallet] The recipient wallet
  # @param amount [Decimal] The amount to transfer
  # @param description [String] Optional description
  # @param metadata [Hash] Additional information about the transaction
  # @return [Result] Success result with transaction details or failure result
  def transfer(destination_wallet, amount, description: nil, metadata: {})
    # Validate inputs
    return Result.failure({ message: "Destination wallet is required", code: :missing_destination }) unless destination_wallet
    return Result.failure({ message: "Amount must be greater than zero", code: :invalid_amount }) unless amount.to_f > 0
    
    # Validate wallet status
    return Result.failure({ message: "Source wallet is inactive", code: :inactive_wallet }) unless wallet.active?
    return Result.failure({ message: "Destination wallet is inactive", code: :inactive_destination }) unless destination_wallet.active?
    
    # Check if trying to transfer to self
    if wallet.id == destination_wallet.id
      return Result.failure({ message: "Cannot transfer to the same wallet", code: :same_wallet })
    end

    # Use the isolation service to execute the transfer with proper isolation
    isolation_service.transaction(:serializable, lock_for_update: true) do |should_lock|
      # Lock wallets if required
      if should_lock
        locked_wallets = isolation_service.lock_wallets(wallet, destination_wallet)
        locked_source = locked_wallets.find { |w| w.id == wallet.id }
        locked_destination = locked_wallets.find { |w| w.id == destination_wallet.id }
      else
        locked_source = wallet
        locked_destination = destination_wallet
      end
      
      # Check balance with locked wallet
      unless locked_source.can_debit?(amount)
        return Result.failure({ 
          message: "Insufficient funds", 
          code: :insufficient_funds,
          details: { available: locked_source.balance, requested: amount }
        })
      end

      # Create transaction via TransactionService
      TransactionService.create_transfer(
        source_wallet: locked_source,
        destination_wallet: locked_destination,
        amount: amount,
        description: description,
        metadata: metadata
      )
    end
  end

  # Get wallet balance with additional context
  # @return [Result] Success result with balance details
  def get_balance
    Result.success({
      balance: wallet.balance,
      currency: wallet.currency,
      available_for_withdrawal: wallet.available_for_withdrawal,
      on_hold: wallet.amount_on_hold,
      updated_at: wallet.balance_updated_at
    })
  end

  # Get transaction history for the wallet
  # @param options [Hash] Filter options
  # @option options [Symbol] :type Transaction type filter
  # @option options [Date] :start_date Start date for filtering
  # @option options [Date] :end_date End date for filtering
  # @option options [Integer] :limit Maximum number of transactions to return
  # @option options [Integer] :offset Offset for pagination
  # @return [Result] Success result with transaction list
  def get_transaction_history(options = {})
    begin
      query = Transaction.where("source_wallet_id = ? OR destination_wallet_id = ?", wallet.id, wallet.id)
      
      # Apply filters
      if options[:type].present?
        query = query.where(transaction_type: options[:type])
      end
      
      if options[:start_date].present?
        query = query.where("created_at >= ?", options[:start_date].beginning_of_day)
      end
      
      if options[:end_date].present?
        query = query.where("created_at <= ?", options[:end_date].end_of_day)
      end
      
      # Apply sorting
      query = query.order(created_at: :desc)
      
      # Apply pagination
      limit = options[:limit] || 50
      offset = options[:offset] || 0
      
      transactions = query.limit(limit).offset(offset)
      total_count = query.count
      
      Result.success({
        transactions: transactions,
        total: total_count,
        limit: limit,
        offset: offset,
        has_more: (offset + transactions.size) < total_count
      })
    rescue => e
      Rails.logger.error("Error fetching transaction history: #{e.message}")
      Result.failure({ 
        message: "Failed to fetch transaction history",
        code: :query_error,
        details: e.message
      })
    end
  end

  # Verify if a wallet can process a transaction
  # @param amount [Decimal] The transaction amount
  # @param transaction_type [Symbol] The type of transaction
  # @return [Result] Success if wallet can process, failure otherwise
  def can_process_transaction?(amount, transaction_type)
    # Validate wallet is active
    return Result.failure({ message: "Wallet is inactive", code: :inactive_wallet }) unless wallet.active?
    
    # For debit transactions, check balance
    if [:withdrawal, :transfer, :payment].include?(transaction_type.to_sym)
      if wallet.can_debit?(amount)
        Result.success({ can_process: true })
      else
        Result.failure({ 
          message: "Insufficient funds", 
          code: :insufficient_funds,
          details: { available: wallet.balance, requested: amount }
        })
      end
    else
      # Credit transactions (like deposits) don't need balance check
      Result.success({ can_process: true })
    end
  end
end
