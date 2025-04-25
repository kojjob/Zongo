class Wallet < ApplicationRecord
  # Relationships
  belongs_to :user
  has_many :sent_transactions, class_name: 'Transaction', foreign_key: 'source_wallet_id'
  has_many :received_transactions, class_name: 'Transaction', foreign_key: 'destination_wallet_id'
  has_many :loans, dependent: :restrict_with_error
  has_many :transactions, dependent: :restrict_with_error

  # Enums
  enum :status, { active: 0, suspended: 1, locked: 2, closed: 3 }

  # Callbacks
  before_validation :generate_wallet_id, on: :create
  after_create :log_wallet_creation

  # Validations
  validates :wallet_id, presence: true, uniqueness: true
  validates :balance, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, inclusion: { in: [ "GHS", "USD", "EUR", "GBP", "NGN" ] }
  validates :daily_limit, presence: true, numericality: { greater_than: 0 }

  # Scopes
  scope :active_wallets, -> { where(status: :active) }
  scope :with_positive_balance, -> { where("balance > 0") }

  before_validation :set_defaults, on: :create

  # Instance methods

  # Get a display name for the wallet
  # @return [String] A display name for the wallet
  def name
    "#{user&.display_name || user&.email || 'Unknown'}'s Wallet (#{wallet_id})"
  end

  def available_balance
    # This could be different from balance if there are pending transactions
    pending_outgoing = self.sent_transactions.where(status: 'pending').sum(:amount)
    self.balance - pending_outgoing
  end

  def pending_balance
    pending_incoming = self.received_transactions.where(status: 'pending').sum(:amount)
    pending_incoming
  end

  def currency_symbol
    case currency
    when 'GHS'
      '₵'
    when 'USD'
      '$'
    when 'EUR'
      '€'
    when 'GBP'
      '£'
    else
      currency
    end
  end


  # Credit the wallet (increase balance)
  # @param amount [Decimal] The amount to add to the wallet balance
  # @param transaction_id [String] The unique transaction identifier
  # @return [Boolean] True if the operation succeeds, false otherwise
  def credit(amount, transaction_id: nil)
    # Validate amount is present and positive
    return false unless amount && amount.positive?

    # Log warning if transaction_id is missing
    Rails.logger.warn("Credit operation called without transaction_id for wallet #{wallet_id}") if transaction_id.nil?

    # Use a transaction to ensure data consistency
    transaction do
      # Update the wallet balance
      # Using update_columns to bypass validations for better performance
      # and avoid unnecessary callbacks
      self.update_columns(
        balance: balance + amount,
        last_transaction_at: Time.current
      )

      # Return true to indicate success
      true
    end
  rescue => e
    # Log the error
    Rails.logger.error("Error crediting wallet #{wallet_id}: #{e.message}")
    # Return false to indicate failure
    false
  end

  # Debit the wallet (decrease balance)
  # @param amount [Decimal] The amount to subtract from the wallet balance
  # @param transaction_id [String] The unique transaction identifier
  # @return [Boolean] True if the operation succeeds, false otherwise
  def debit(amount, transaction_id: nil)
    # Validate amount is present, positive, and sufficient balance
    return false unless amount && amount.positive? && amount <= balance

    # Log warning if transaction_id is missing
    Rails.logger.warn("Debit operation called without transaction_id for wallet #{wallet_id}") if transaction_id.nil?

    # Use a transaction to ensure data consistency
    transaction do
      # Update the wallet balance
      # Using update_columns to bypass validations for better performance
      # and avoid unnecessary callbacks
      self.update_columns(
        balance: balance - amount,
        last_transaction_at: Time.current
      )

      # Return true to indicate success
      true
    end
  rescue => e
    # Log the error
    Rails.logger.error("Error debiting wallet #{wallet_id}: #{e.message}")
    # Return false to indicate failure
    false
  end

  # Check if a debit of the specified amount is possible
  # @param amount [Decimal] The amount to check
  # @return [Boolean] True if the debit is possible, false otherwise
  def can_debit?(amount)
    active? && amount.positive? && amount <= balance
  end

  # Check if daily transaction limit has been reached
  # @param amount [Decimal] The amount of the new transaction
  # @return [Boolean] True if the transaction would exceed the limit, false otherwise
  def daily_limit_exceeded?(amount)
    return false unless amount.positive?

    # Calculate total debits for the current day
    todays_total = sent_transactions
                    .where("created_at >= ?", Time.current.beginning_of_day)
                    .where(status: :completed)
                    .sum(:amount)

    # Check if the new amount would exceed the daily limit
    (todays_total + amount) > daily_limit
  end

  # Get recent transactions (both incoming and outgoing)
  # @param limit [Integer] Maximum number of transactions to return
  # @return [Array<Transaction>] Array of recent transactions
  def recent_transactions(limit = 10)
    # Ensure id is present to avoid SQL errors
    return Transaction.none unless id.present?

    Transaction.where("source_wallet_id = ? OR destination_wallet_id = ?", id, id)
               .order(created_at: :desc)
               .limit(limit)
  end

  # Get the transaction history for a specific time period
  # @param start_date [Date] The start date of the period
  # @param end_date [Date] The end date of the period
  # @return [Array<Transaction>] Array of transactions within the specified period
  def transaction_history(start_date:, end_date:)
    # Ensure id is present to avoid SQL errors
    return Transaction.none unless id.present?

    Transaction.where("(source_wallet_id = ? OR destination_wallet_id = ?) AND created_at BETWEEN ? AND ?",
                     id, id, start_date.beginning_of_day, end_date.end_of_day)
               .order(created_at: :desc)
  end

  # Get total incoming amount for a specific period
  # @param start_date [Date] The start date of the period
  # @param end_date [Date] The end date of the period
  # @return [Decimal] Total incoming amount
  def total_incoming(start_date:, end_date:)
    # Ensure id is present to avoid SQL errors
    return 0 unless id.present?

    received_transactions
      .where(status: :completed)
      .where("created_at BETWEEN ? AND ?", start_date.beginning_of_day, end_date.end_of_day)
      .sum(:amount)
  end

  # Get total outgoing amount for a specific period
  # @param start_date [Date] The start date of the period
  # @param end_date [Date] The end date of the period
  # @return [Decimal] Total outgoing amount
  def total_outgoing(start_date:, end_date:)
    # Ensure id is present to avoid SQL errors
    return 0 unless id.present?

    sent_transactions
      .where(status: :completed)
      .where("created_at BETWEEN ? AND ?", start_date.beginning_of_day, end_date.end_of_day)
      .sum(:amount)
  end

  # Format the balance with the currency symbol
  # @return [String] Formatted balance
  def formatted_balance
    "#{currency_symbol}#{balance.to_f.round(2)}"
  end

  private

  # Generate a unique wallet ID if not provided
  def generate_wallet_id
    return if wallet_id.present?

    # Generate a unique ID with 'W' prefix followed by 12 alphanumeric characters
    loop do
      self.wallet_id = "W#{SecureRandom.alphanumeric(12).upcase}"
      break unless Wallet.exists?(wallet_id: wallet_id)
    end
  end

  # Set default values for new wallets
  def set_defaults
    self.balance ||= 0.0
    self.currency ||= 'GHS'
  end

  # Log wallet creation event
  def log_wallet_creation
    Rails.logger.info("Wallet created: #{wallet_id} for User ID: #{user_id}")
    # Additional auditing or event publishing could be added here
  end
end
