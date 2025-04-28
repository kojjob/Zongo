class Transaction < ApplicationRecord
  # Relationships
  belongs_to :source_wallet, class_name: "Wallet", optional: true
  belongs_to :destination_wallet, class_name: "Wallet", optional: true
  belongs_to :scheduled_transaction, optional: true
  has_many :wallet_transactions, dependent: :destroy
  has_many :bill_payments, foreign_key: "transaction_id", dependent: :destroy
  has_many :security_logs, as: :loggable, dependent: :destroy
  has_many :orders, foreign_key: "transaction_id", dependent: :nullify

  # Indirect relationships via wallets
  has_one :sender, through: :source_wallet, source: :user
  has_one :recipient, through: :destination_wallet, source: :user

  # Enums
  enum :transaction_type, {
    deposit: 0,     # Money coming into the system
    withdrawal: 1,  # Money leaving the system
    transfer: 2,    # Internal transfer between wallets
    payment: 3      # Payment for goods or services
  }, default: :deposit

  enum :status, {
    pending: 0,     # Initial state
    completed: 1,   # Successfully processed
    failed: 2,      # Transaction failed
    reversed: 3,    # Transaction was reversed/refunded
    blocked: 4      # Transaction was blocked by security checks
  }, default: :pending, prefix: true

  enum :payment_method, {
    mobile_money: 0,
    bank_transfer: 1,
    card_payment: 2,
    cash: 3,
    wallet: 4
  }, default: :mobile_money, prefix: true

  # Validations
  validates :transaction_id, presence: true, uniqueness: true
  validates :transaction_type, presence: true
  validates :status, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true
  validate :validate_wallet_associations

  # Callbacks
  before_validation :generate_transaction_id, on: :create
  before_validation :set_default_timestamps, on: :create
  after_create :log_transaction_initiated
  after_update :log_transaction_status_change, if: :saved_change_to_status?

  # Scopes
  scope :completed, -> { where(status: 'completed') }
  scope :successful, -> { where(status: 'completed') } # Alias for completed
  scope :pending, -> { where(status: 'pending') }
  scope :failed, -> { where(status: 'failed') }
  scope :transfers, -> { where(transaction_type: 'transfer') }
  scope :bill_payments, -> { where(transaction_type: 'bill_payment') }
  scope :by_date_range, ->(start_date, end_date) {
    where("created_at BETWEEN ? AND ?", start_date.beginning_of_day, end_date.end_of_day)
  }
  scope :by_user, ->(user_id) {
    joins("LEFT JOIN wallets source ON source.id = transactions.source_wallet_id")
    .joins("LEFT JOIN wallets dest ON dest.id = transactions.destination_wallet_id")
    .where("source.user_id = ? OR dest.user_id = ?", user_id, user_id)
  }
  scope :blocked, -> { where(status: :blocked) }

  # Class methods

  # Create a deposit transaction
  # @param wallet [Wallet] The destination wallet
  # @param amount [Decimal] The amount to deposit
  # @param payment_method [Symbol] How the money is being deposited
  # @param provider [String] The payment provider name
  # @param metadata [Hash] Additional information about the transaction
  # @param apply_fee [Boolean] Whether to apply transaction fee
  # @return [Transaction] The created transaction object
  def self.create_deposit(wallet:, amount:, payment_method:, provider:, metadata: {}, apply_fee: true)
    # Calculate fee if applicable
    fee = apply_fee && defined?(TransactionFee) ? TransactionFee.calculate_fee_for(:deposit, amount) : 0

    create(
      transaction_type: :deposit,
      status: :pending,
      amount: amount,
      fee: fee,
      currency: wallet.currency,
      destination_wallet_id: wallet.id,
      payment_method: payment_method,
      provider: provider,
      metadata: metadata,
      initiated_at: Time.current
    )
  end

  # Create a withdrawal transaction
  # @param wallet [Wallet] The source wallet
  # @param amount [Decimal] The amount to withdraw
  # @param payment_method [Symbol] How the money is being withdrawn
  # @param provider [String] The payment provider name
  # @param metadata [Hash] Additional information about the transaction
  # @param apply_fee [Boolean] Whether to apply transaction fee
  # @return [Transaction] The created transaction object
  def self.create_withdrawal(wallet:, amount:, payment_method:, provider:, metadata: {}, apply_fee: true)
    # Calculate fee if applicable
    fee = apply_fee && defined?(TransactionFee) ? TransactionFee.calculate_fee_for(:withdrawal, amount) : 0

    create(
      transaction_type: :withdrawal,
      status: :pending,
      amount: amount,
      fee: fee,
      currency: wallet.currency,
      source_wallet_id: wallet.id,
      payment_method: payment_method,
      provider: provider,
      metadata: metadata,
      initiated_at: Time.current
    )
  end

  # Create a transfer transaction between two wallets
  # @param source_wallet [Wallet] The sender's wallet
  # @param destination_wallet [Wallet] The recipient's wallet
  # @param amount [Decimal] The amount to transfer
  # @param description [String] Description of the transfer
  # @param metadata [Hash] Additional information about the transaction
  # @param apply_fee [Boolean] Whether to apply transaction fee
  # @return [Transaction] The created transaction object
  def self.create_transfer(source_wallet:, destination_wallet:, amount:, description: nil, metadata: {}, apply_fee: true)
    # Calculate fee if applicable
    fee = apply_fee && defined?(TransactionFee) ? TransactionFee.calculate_fee_for(:transfer, amount) : 0

    create(
      transaction_type: :transfer,
      status: :pending,
      amount: amount,
      fee: fee,
      currency: source_wallet.currency,
      source_wallet_id: source_wallet.id,
      destination_wallet_id: destination_wallet.id,
      payment_method: :wallet,
      description: description,
      metadata: metadata,
      initiated_at: Time.current
    )
  end

  # Create a payment transaction
  # @param source_wallet [Wallet] The sender's wallet
  # @param destination_wallet [Wallet] The recipient's wallet (merchant)
  # @param amount [Decimal] The amount to pay
  # @param description [String] Description of the payment
  # @param metadata [Hash] Additional information about the transaction
  # @param apply_fee [Boolean] Whether to apply transaction fee
  # @return [Transaction] The created transaction object
  def self.create_payment(source_wallet:, destination_wallet:, amount:, description: nil, metadata: {}, apply_fee: true)
    # Calculate fee if applicable
    fee = apply_fee && defined?(TransactionFee) ? TransactionFee.calculate_fee_for(:payment, amount) : 0

    create(
      transaction_type: :payment,
      status: :pending,
      amount: amount,
      fee: fee,
      currency: source_wallet.currency,
      source_wallet_id: source_wallet.id,
      destination_wallet_id: destination_wallet.id,
      payment_method: :wallet,
      description: description,
      metadata: metadata,
      initiated_at: Time.current
    )
  end

  # Instance methods

  # Perform security check on the transaction
  # @param user [User] The user performing the transaction
  # @param ip_address [String] The IP address of the request
  # @param user_agent [String] The user agent of the request
  # @return [Boolean] True if the transaction passes security checks
  def security_check(user, ip_address = nil, user_agent = nil)
    security_service = TransactionSecurityService.new(self, user, ip_address, user_agent)
    result = security_service.secure?

    # Log security check results
    log_data = security_service.log_security_check(result)

    # Create security log entry
    severity = result ? :info : :warning
    SecurityLog.log_event(
      user,
      result ? :transaction_check : :transaction_blocked,
      severity: severity,
      details: {
        transaction_id: id,
        transaction_type: transaction_type,
        amount: amount,
        currency: currency,
        risk_score: log_data[:risk_score],
        errors: security_service.errors
      },
      ip_address: ip_address,
      user_agent: user_agent,
      loggable: self
    )

    # If security check failed, update transaction status
    unless result
      update(
        status: :blocked,
        metadata: metadata.merge(
          security_check: {
            failed_at: Time.current,
            reasons: security_service.errors,
            risk_score: log_data[:risk_score]
          }
        )
      )
    end

    result
  end

  # Complete a transaction
  # @param external_reference [String] External reference from payment processor
  # @return [Boolean] True if completed successfully, false otherwise
  def complete!(external_reference: nil)
    return false unless status_pending?

    # Use TransactionIsolationService to handle the transaction with proper isolation
    isolation_service = TransactionIsolationService.new
    result = isolation_service.transaction(:serializable, lock_for_update: true) do |_|
      # Process based on transaction type
      case transaction_type
      when "deposit"
        result = destination_wallet.credit(amount, transaction_id: transaction_id)
      when "withdrawal"
        result = source_wallet.debit(amount, transaction_id: transaction_id)
      when "transfer"
        # For transfers, debit source and credit destination
        # Lock both wallets in consistent order to prevent deadlocks
        source_wallet_id, destination_wallet_id = [source_wallet.id, destination_wallet.id].sort
        locked_source = source_wallet_id == source_wallet.id ?
                       Wallet.where(id: source_wallet_id).lock("FOR UPDATE").first :
                       Wallet.where(id: destination_wallet_id).lock("FOR UPDATE").first

        locked_destination = source_wallet_id == source_wallet.id ?
                            Wallet.where(id: destination_wallet_id).lock("FOR UPDATE").first :
                            Wallet.where(id: source_wallet_id).lock("FOR UPDATE").first

        # Need to make sure we're using the right wallets
        debit_wallet = locked_source.id == source_wallet.id ? locked_source : locked_destination
        credit_wallet = locked_destination.id == destination_wallet.id ? locked_destination : locked_source

        debit_result = debit_wallet.debit(amount, transaction_id: transaction_id)
        credit_result = credit_wallet.credit(amount, transaction_id: transaction_id)
        result = debit_result && credit_result
      when "payment"
        # Similar to transfer but may involve different logic
        result = source_wallet.debit(amount, transaction_id: transaction_id)
      end

      if result
        # Update transaction state
        self.update(
          status: :completed,
          completed_at: Time.current,
          external_reference: external_reference
        )

        # Log successful transaction
        user = source_wallet&.user || destination_wallet.user
        SecurityLog.log_event(
          user,
          :transaction_completed,
          severity: :info,
          details: {
            transaction_id: id,
            transaction_type: transaction_type,
            amount: amount,
            currency: currency,
            status: :completed
          },
          loggable: self
        ) if defined?(SecurityLog)

        true
      else
        # Mark as failed if wallet operations didn't succeed
        self.update(
          status: :failed,
          failed_at: Time.current
        )

        # Log failed transaction
        user = source_wallet&.user || destination_wallet&.user
        if defined?(SecurityLog) && user.present?
          SecurityLog.log_event(
            user,
            :transaction_failed,
            severity: :warning,
            details: {
              transaction_id: id,
              transaction_type: transaction_type,
              amount: amount,
              currency: currency,
              status: :failed,
              reason: "Wallet operation failed"
            },
            loggable: self
          )
        end

        false
      end
    end

    # Return the result - will be true if successful, false if failed
    return result.success? && result.data ? true : false
  rescue => e
    Rails.logger.error("Error completing transaction #{transaction_id}: #{e.message}")
    self.update(
      status: :failed,
      failed_at: Time.current
    )

    # Log error
    user = source_wallet&.user || destination_wallet&.user
    if user && defined?(SecurityLog)
      SecurityLog.log_event(
        user,
        :transaction_error,
        severity: :warning,
        details: {
          transaction_id: id,
          transaction_type: transaction_type,
          amount: amount,
          currency: currency,
          status: :failed,
          error: e.message
        },
        loggable: self
      )
    end

    false
  end

  # Mark a transaction as failed
  # @param reason [String] Reason for failure
  # @return [Boolean] True if updated successfully
  def fail!(reason: nil)
    return false unless status_pending?

    result = self.update(
      status: :failed,
      failed_at: Time.current,
      metadata: metadata.merge(failure_reason: reason)
    )

    # Log failure
    if result
      user = source_wallet&.user || destination_wallet&.user
      if user
        SecurityLog.log_event(
          user,
          :transaction_check,
          severity: :warning,
          details: {
            transaction_id: id,
            transaction_type: transaction_type,
            amount: amount,
            currency: currency,
            status: :failed,
            reason: reason
          },
          loggable: self
        )
      end
    end

    result
  end

  # Reverse/refund a completed transaction
  # @param reason [String] Reason for reversal
  # @return [Boolean] True if reversed successfully, false otherwise
  def reverse!(reason: nil)
    return false unless status_completed?

    # Use TransactionIsolationService to handle the transaction with proper isolation
    isolation_service = TransactionIsolationService.new
    result = isolation_service.transaction(:serializable, lock_for_update: true) do |_|
      # Process reversal based on transaction type
      case transaction_type
      when "deposit"
        # Lock the wallet before operation
        locked_wallet = isolation_service.lock_wallet(destination_wallet)
        result = locked_wallet.debit(amount, transaction_id: "REV-#{transaction_id}")
      when "withdrawal"
        # Lock the wallet before operation
        locked_wallet = isolation_service.lock_wallet(source_wallet)
        result = locked_wallet.credit(amount, transaction_id: "REV-#{transaction_id}")
      when "transfer", "payment"
        # Reverse transfer: credit source, debit destination
        # Lock both wallets in consistent order to prevent deadlocks
        source_wallet_id, destination_wallet_id = [source_wallet.id, destination_wallet.id].sort
        locked_source = source_wallet_id == source_wallet.id ?
                       Wallet.where(id: source_wallet_id).lock("FOR UPDATE").first :
                       Wallet.where(id: destination_wallet_id).lock("FOR UPDATE").first

        locked_destination = source_wallet_id == source_wallet.id ?
                            Wallet.where(id: destination_wallet_id).lock("FOR UPDATE").first :
                            Wallet.where(id: source_wallet_id).lock("FOR UPDATE").first

        # Need to make sure we're using the right wallets
        source_locked = locked_source.id == source_wallet.id ? locked_source : locked_destination
        destination_locked = locked_destination.id == destination_wallet.id ? locked_destination : locked_source

        credit_result = source_locked.credit(amount, transaction_id: "REV-#{transaction_id}")
        debit_result = destination_locked.debit(amount, transaction_id: "REV-#{transaction_id}")
        result = credit_result && debit_result
      end

      if result
        # Update transaction state
        update_result = self.update(
          status: :reversed,
          reversed_at: Time.current,
          metadata: metadata.merge(reversal_reason: reason)
        )

        # Log reversal
        if update_result
          user = source_wallet&.user || destination_wallet&.user
          if user && defined?(SecurityLog)
            SecurityLog.log_event(
              user,
              :transaction_reversed,
              severity: :info,
              details: {
                transaction_id: id,
                transaction_type: transaction_type,
                amount: amount,
                currency: currency,
                status: :reversed,
                reason: reason
              },
              loggable: self
            )
          end
        end

        update_result
      else
        false
      end
    end

    # Return the result - will be true if successful, false if failed
    return result.success? && result.data ? true : false
  rescue => e
    Rails.logger.error("Error reversing transaction #{transaction_id}: #{e.message}")

    # Log error
    user = source_wallet&.user || destination_wallet&.user
    if user && defined?(SecurityLog)
      SecurityLog.log_event(
        user,
        :transaction_reversal_error,
        severity: :warning,
        details: {
          transaction_id: id,
          transaction_type: transaction_type,
          amount: amount,
          currency: currency,
          status: :failed,
          action: "reversal",
          error: e.message
        },
        loggable: self
      )
    end

    false
  end

  # Get the transaction reference ID for display
  # @return [String] Formatted transaction reference
  def reference
    "TXN-#{transaction_id[0..7]}"
  end

  # Get human-readable transaction type description
  # @return [String] Transaction type description
  def transaction_type_description
    case transaction_type
    when "deposit" then "Deposit to Wallet"
    when "withdrawal" then "Withdrawal from Wallet"
    when "transfer" then "Wallet Transfer"
    when "payment" then "Payment"
    else "Unknown Transaction"
    end
  end

  # Get the recipient's name for display
  # @return [String, nil] Recipient name or nil if not applicable
  def recipient_name
    return nil unless destination_wallet&.user.present?
    destination_wallet.user.display_name
  end

  # Get the source's name for display
  # @return [String, nil] Source name or nil if not applicable
  def source_name
    return nil unless source_wallet&.user.present?
    source_wallet.user.display_name
  end

  # Get the name of the other party in the transaction for a specific user
  # @param user_id [Integer] User ID to check
  # @return [String] Name of the other party
  def other_party_name(user_id)
    if source_wallet&.user_id == user_id
      recipient_name || "Unknown Recipient"
    elsif destination_wallet&.user_id == user_id
      source_name || "Unknown Sender"
    else
      "Unknown Party"
    end
  end

  # Determine whether this transaction resulted in money coming in or going out for a specific user
  # @param user_id [Integer] User ID to check
  # @return [Symbol] :incoming, :outgoing, or :internal
  def direction_for_user(user_id)
    if source_wallet&.user_id == user_id && destination_wallet&.user_id == user_id
      :internal
    elsif destination_wallet&.user_id == user_id
      :incoming
    elsif source_wallet&.user_id == user_id
      :outgoing
    else
      :unknown
    end
  end

  # Get the transaction amount with sign based on direction for a user
  # @param user_id [Integer] User ID to check
  # @return [String] Formatted amount with sign and currency
  def signed_amount_for_user(user_id)
    dir = direction_for_user(user_id)

    case dir
    when :incoming
      "+#{formatted_amount}"
    when :outgoing
      "-#{formatted_amount}"
    else
      formatted_amount
    end
  end

  # Format amount with currency symbol
  # @return [String] Formatted amount
  def formatted_amount
    symbol = case currency
    when "GHS" then "₵"
    when "USD" then "$"
    when "EUR" then "€"
    when "GBP" then "£"
    when "NGN" then "₦"
    else ""
    end

    "#{symbol}#{amount.to_f.round(2)}"
  end

  # Get the other party's name (for transfers)
  # @param user_id [Integer] The current user's ID
  # @return [String] The other party's name or description
  def other_party_name(user_id)
    if sender&.id == user_id
      recipient&.display_name || "Unknown Recipient"
    elsif recipient&.id == user_id
      sender&.display_name || "Unknown Sender"
    else
      "Unknown Party"
    end
  end

  private

  # Generate a unique transaction ID
  def generate_transaction_id
    return if transaction_id.present?

    # Generate a unique ID with prefix based on transaction type
    prefix = case transaction_type
    when "deposit" then "DEP"
    when "withdrawal" then "WIT"
    when "transfer" then "TRF"
    when "payment" then "PAY"
    when "airtime" then "AIR"
    else "TXN"
    end

    timestamp = Time.current.strftime('%Y%m%d%H%M%S')
    random_suffix = SecureRandom.hex(3).upcase

    loop do
      new_id = "#{prefix}#{timestamp}#{random_suffix}"
      unless Transaction.exists?(transaction_id: new_id)
        self.transaction_id = new_id
        break
      end
      random_suffix = SecureRandom.hex(3).upcase
    end
  end

  # Set default timestamps based on status
  def set_default_timestamps
    self.initiated_at ||= Time.current if status_pending?
    self.completed_at ||= Time.current if status_completed?
    self.failed_at ||= Time.current if status_failed?
    self.reversed_at ||= Time.current if status_reversed?
  end

  # Validate the wallet associations based on transaction type
  def validate_wallet_associations
    case transaction_type
    when "deposit"
      errors.add(:destination_wallet, "must be present for deposits") if destination_wallet_id.blank?
    when "withdrawal"
      errors.add(:source_wallet, "must be present for withdrawals") if source_wallet_id.blank?
    when "transfer", "payment"
      errors.add(:source_wallet, "must be present for transfers and payments") if source_wallet_id.blank?
      errors.add(:destination_wallet, "must be present for transfers and payments") if destination_wallet_id.blank?

      if source_wallet_id.present? && destination_wallet_id.present? && source_wallet_id == destination_wallet_id
        errors.add(:base, "Source and destination wallets cannot be the same")
      end
    end
  end

  # Log transaction initiation
  def log_transaction_initiated
    Rails.logger.info("Transaction initiated: #{transaction_id} - Type: #{transaction_type} - Amount: #{formatted_amount}")
  end

  # Log transaction status changes
  def log_transaction_status_change
    Rails.logger.info("Transaction status changed: #{transaction_id} - From: #{status_before_last_save} - To: #{status}")
  end
end
