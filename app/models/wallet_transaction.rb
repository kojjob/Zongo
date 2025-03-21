class WalletTransaction < ApplicationRecord
  # Associations
  belongs_to :wallet
  has_one :user, through: :wallet
  
  # Validations
  validates :transaction_type, :status, presence: true
  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :reference, uniqueness: true, allow_nil: true
  
  # Money handling
  monetize :amount_cents
  
  # Enums
  enum :transaction_type, {
    deposit: 0,
    withdrawal: 1,
    transfer_in: 2,
    transfer_out: 3,
    payment: 4,
    refund: 5,
    reversal: 6
  }
  
  enum :status, {
    pending: 0,
    completed: 1,
    failed: 2,
    reversed: 3
  }
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :successful, -> { where(status: [:completed]) }
  scope :pending_or_completed, -> { where(status: [:pending, :completed]) }
  
  # Store metadata as JSON
  serialize :metadata, JSON
  
  # Callbacks
  before_create :generate_reference, unless: :reference?
  after_create :notify_user
  
  # Custom class methods
  def self.find_by_reference(reference)
    find_by(reference: reference)
  end
  
  def self.total_for_period(start_date, end_date, type = nil)
    scope = where(created_at: start_date.beginning_of_day..end_date.end_of_day)
    scope = scope.where(transaction_type: type) if type.present?
    scope.sum(:amount_cents)
  end
  
  # Instance methods
  def description
    case transaction_type
    when 'deposit'
      "Deposit from #{source}"
    when 'withdrawal'
      "Withdrawal to #{destination}"
    when 'transfer_in'
      "Transfer from #{source}"
    when 'transfer_out'
      "Transfer to #{destination}"
    when 'payment'
      "Payment to #{destination}"
    when 'refund'
      "Refund from #{source}"
    when 'reversal'
      "Reversal of transaction #{metadata['original_reference']}"
    else
      "Transaction #{reference}"
    end
  end
  
  def reverse!
    raise IrreversibleTransactionError if reversed?
    
    transaction do
      # Create reversal transaction
      reversal = wallet.transactions.create!(
        transaction_type: :reversal,
        amount_cents: amount_cents,
        source: destination.presence || 'system',
        destination: source.presence || 'system',
        status: :completed,
        reference: SecureRandom.uuid,
        metadata: {
          original_reference: reference,
          reason: 'User requested reversal'
        }
      )
      
      # Update wallet balance
      case transaction_type
      when 'deposit', 'transfer_in', 'refund'
        wallet.update!(balance_cents: wallet.balance_cents - amount_cents)
      when 'withdrawal', 'transfer_out', 'payment'
        wallet.update!(balance_cents: wallet.balance_cents + amount_cents)
      end
      
      # Mark this transaction as reversed
      update!(status: :reversed)
      
      return reversal
    end
  end
  
  # Custom error classes
  class IrreversibleTransactionError < StandardError; end
  
  private
  
  def generate_reference
    self.reference = "TXN-#{SecureRandom.alphanumeric(8).upcase}"
  end
  
  def notify_user
    # This will be implemented with a background job
    # TransactionNotificationJob.perform_later(id)
  end
end