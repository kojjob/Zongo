class ScheduledTransaction < ApplicationRecord
  belongs_to :source_wallet, class_name: 'Wallet', foreign_key: 'source_wallet_id'
  belongs_to :destination_wallet, class_name: 'Wallet', foreign_key: 'destination_wallet_id', optional: true

  # Validations
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :frequency, presence: true
  validates :next_occurrence, presence: true
  validates :transaction_type, presence: true
  validates :status, presence: true

  # Enums
  enum :transaction_type, {
    transfer: 0,
    deposit: 1,
    withdrawal: 2,
    payment: 3
  },  prefix: true

  enum :frequency, {
    daily: 0,
    weekly: 1,
    biweekly: 2,
    monthly: 3,
    quarterly: 4
  },  prefix: true

  enum :status, {
    active: 0,
    paused: 1,
    completed: 2,
    cancelled: 3,
    failed: 4
  }, default: :active, prefix: true

  # Scopes
  scope :upcoming, -> { where(status: :active).where('next_occurrence <= ?', 7.days.from_now) }
  scope :due_today, -> { where(status: :active).where('next_occurrence <= ?', Date.current.end_of_day) }
  scope :owned_by, ->(user_id) { joins(:source_wallet).where(wallets: { user_id: user_id }) }

  # Methods
  def transaction_type_description
    case transaction_type
    when 'transfer' then 'Transfer'
    when 'deposit' then 'Deposit'
    when 'withdrawal' then 'Withdrawal'
    when 'payment' then 'Payment'
    end
  end

  def frequency_description
    case frequency
    when 'daily' then 'Daily'
    when 'weekly' then 'Weekly'
    when 'biweekly' then 'Bi-weekly'
    when 'monthly' then 'Monthly'
    when 'quarterly' then 'Quarterly'
    end
  end

  def recipient
    return nil unless destination_wallet
    destination_wallet.user
  end

  def recipient_name
    return payment_destination if transaction_type == 'payment'
    return 'Self' if transaction_type == 'deposit' || transaction_type == 'withdrawal'
    recipient&.display_name || 'Unknown'
  end

  def formatted_amount
    "#{source_wallet.currency_symbol}#{amount.to_f.round(2)}"
  end

  def calculate_next_occurrence
    case frequency
    when 'daily'
      next_occurrence + 1.day
    when 'weekly'
      next_occurrence + 1.week
    when 'biweekly'
      next_occurrence + 2.weeks
    when 'monthly'
      next_occurrence + 1.month
    when 'quarterly'
      next_occurrence + 3.months
    end
  end

  def execute_transaction
    return false unless active?
    return false if next_occurrence > Time.current

    transaction = nil

    case transaction_type
    when 'transfer'
      transaction = Transaction.create_transfer(
        source_wallet: source_wallet,
        destination_wallet: destination_wallet,
        amount: amount,
        description: description || "Scheduled transfer",
        metadata: {
          scheduled_transaction_id: id,
          sender_name: source_wallet.user.display_name,
          recipient_name: recipient_name
        }
      )
    when 'deposit'
      transaction = Transaction.create_deposit(
        wallet: source_wallet,
        amount: amount,
        payment_method: payment_method,
        provider: payment_provider,
        metadata: {
          scheduled_transaction_id: id,
          description: description || "Scheduled deposit"
        }
      )
    when 'withdrawal'
      transaction = Transaction.create_withdrawal(
        wallet: source_wallet,
        amount: amount,
        payment_method: payment_method,
        provider: payment_provider,
        metadata: {
          scheduled_transaction_id: id,
          description: description || "Scheduled withdrawal"
        }
      )
    when 'payment'
      transaction = Transaction.create_payment(
        wallet: source_wallet,
        amount: amount,
        recipient: payment_destination,
        description: description || "Scheduled payment",
        metadata: {
          scheduled_transaction_id: id
        }
      )
    end

    if transaction&.persisted?
      transaction.complete!
      
      # Update scheduled transaction
      self.occurrences_count += 1
      
      if occurrences_limit.present? && occurrences_count >= occurrences_limit
        self.status = :completed
      else
        self.last_occurrence = next_occurrence
        self.next_occurrence = calculate_next_occurrence
      end
      
      save
      true
    else
      self.status = :failed
      save
      false
    end
  end
end
