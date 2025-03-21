class Transaction < ApplicationRecord
  # Relationships
  belongs_to :source_wallet, class_name: 'Wallet', optional: true
  belongs_to :destination_wallet, class_name: 'Wallet', optional: true
  
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
    reversed: 3     # Transaction was reversed/refunded
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
  scope :successful, -> { where(status: :completed) }
  scope :pending_or_failed, -> { where(status: [:pending, :failed]) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_date_range, ->(start_date, end_date) {
    where('created_at BETWEEN ? AND ?', start_date.beginning_of_day, end_date.end_of_day)
  }
  scope :by_user, ->(user_id) {
    joins("LEFT JOIN wallets source ON source.id = transactions.source_wallet_id")
    .joins("LEFT JOIN wallets dest ON dest.id = transactions.destination_wallet_id")
    .where("source.user_id = ? OR dest.user_id = ?", user_id, user_id)
  }
  
  # Class methods
  
  # Create a deposit transaction
  # @param wallet [Wallet] The destination wallet
  # @param amount [Decimal] The amount to deposit
  # @param payment_method [Symbol] How the money is being deposited
  # @param provider [String] The payment provider name
  # @param metadata [Hash] Additional information about the transaction
  # @return [Transaction] The created transaction object
  def self.create_deposit(wallet:, amount:, payment_method:, provider:, metadata: {})
    create(
      transaction_type: :deposit,
      status: :pending,
      amount: amount,
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
  # @return [Transaction] The created transaction object
  def self.create_withdrawal(wallet:, amount:, payment_method:, provider:, metadata: {})
    create(
      transaction_type: :withdrawal,
      status: :pending,
      amount: amount,
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
  # @return [Transaction] The created transaction object
  def self.create_transfer(source_wallet:, destination_wallet:, amount:, description: nil, metadata: {})
    create(
      transaction_type: :transfer,
      status: :pending,
      amount: amount,
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
  
  # Complete a transaction
  # @param external_reference [String] External reference from payment processor
  # @return [Boolean] True if completed successfully, false otherwise
  def complete!(external_reference: nil)
    return false unless pending?
    
    transaction do
      # Process based on transaction type
      case transaction_type
      when 'deposit'
        result = destination_wallet.credit(amount, transaction_id: transaction_id)
      when 'withdrawal'
        result = source_wallet.debit(amount, transaction_id: transaction_id)
      when 'transfer'
        # For transfers, debit source and credit destination
        debit_result = source_wallet.debit(amount, transaction_id: transaction_id)
        credit_result = destination_wallet.credit(amount, transaction_id: transaction_id)
        result = debit_result && credit_result
      when 'payment'
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
        return true
      else
        # Mark as failed if wallet operations didn't succeed
        self.update(
          status: :failed,
          failed_at: Time.current
        )
        return false
      end
    end
  rescue => e
    Rails.logger.error("Error completing transaction #{transaction_id}: #{e.message}")
    self.update(
      status: :failed,
      failed_at: Time.current
    )
    false
  end
  
  # Mark a transaction as failed
  # @param reason [String] Reason for failure
  # @return [Boolean] True if updated successfully
  def fail!(reason: nil)
    return false unless pending?
    
    self.update(
      status: :failed,
      failed_at: Time.current,
      metadata: metadata.merge(failure_reason: reason)
    )
  end
  
  # Reverse/refund a completed transaction
  # @param reason [String] Reason for reversal
  # @return [Boolean] True if reversed successfully, false otherwise
  def reverse!(reason: nil)
    return false unless completed?
    
    transaction do
      # Process reversal based on transaction type
      case transaction_type
      when 'deposit'
        result = destination_wallet.debit(amount, transaction_id: "REV-#{transaction_id}")
      when 'withdrawal'
        result = source_wallet.credit(amount, transaction_id: "REV-#{transaction_id}")
      when 'transfer', 'payment'
        # Reverse transfer: credit source, debit destination
        credit_result = source_wallet.credit(amount, transaction_id: "REV-#{transaction_id}")
        debit_result = destination_wallet.debit(amount, transaction_id: "REV-#{transaction_id}")
        result = credit_result && debit_result
      end
      
      if result
        # Update transaction state
        self.update(
          status: :reversed,
          reversed_at: Time.current,
          metadata: metadata.merge(reversal_reason: reason)
        )
        return true
      else
        return false
      end
    end
  rescue => e
    Rails.logger.error("Error reversing transaction #{transaction_id}: #{e.message}")
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
    when 'deposit' then 'Deposit to Wallet'
    when 'withdrawal' then 'Withdrawal from Wallet'
    when 'transfer' then 'Wallet Transfer'
    when 'payment' then 'Payment'
    else 'Unknown Transaction'
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
             when 'GHS' then '₵'
             when 'USD' then '$'
             when 'EUR' then '€'
             when 'GBP' then '£'
             when 'NGN' then '₦'
             else ''
             end
    
    "#{symbol}#{amount.to_f.round(2)}"
  end
  
  # Get the other party's name (for transfers)
  # @param user_id [Integer] The current user's ID
  # @return [String] The other party's name or description
  def other_party_name(user_id)
    if sender&.id == user_id
      recipient&.display_name || 'Unknown Recipient'
    elsif recipient&.id == user_id
      sender&.display_name || 'Unknown Sender'
    else
      'Unknown Party'
    end
  end
  
  private
  
  # Generate a unique transaction ID
  def generate_transaction_id
    return if transaction_id.present?
    
    # Generate a unique ID with prefix based on transaction type
    prefix = case transaction_type
             when 'deposit' then 'DEP'
             when 'withdrawal' then 'WIT'
             when 'transfer' then 'TRF'
             when 'payment' then 'PAY'
             else 'TXN'
             end
    
    loop do
      self.transaction_id = "#{prefix}#{Time.current.strftime('%Y%m%d')}#{SecureRandom.alphanumeric(8).upcase}"
      break unless Transaction.exists?(transaction_id: transaction_id)
    end
  end
  
  # Set default timestamps based on status
  def set_default_timestamps
    self.initiated_at ||= Time.current if pending?
    self.completed_at ||= Time.current if completed?
    self.failed_at ||= Time.current if failed?
    self.reversed_at ||= Time.current if reversed?
  end
  
  # Validate the wallet associations based on transaction type
  def validate_wallet_associations
    case transaction_type
    when 'deposit'
      errors.add(:destination_wallet, "must be present for deposits") if destination_wallet_id.blank?
    when 'withdrawal'
      errors.add(:source_wallet, "must be present for withdrawals") if source_wallet_id.blank?
    when 'transfer', 'payment'
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
