class BillPayment < ApplicationRecord
  # Relationships
  belongs_to :user
  belongs_to :payment_transaction, class_name: "Transaction", foreign_key: "transaction_id", optional: true

  # Validations
  validates :bill_type, presence: true
  validates :provider, presence: true
  validates :account_number, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true

  # Enums
  enum bill_type: { electricity: 0, water: 1, internet: 2, airtime: 3, tv: 4, gas: 5, insurance: 6, other: 7 }
  enum status: { pending: 0, processing: 1, completed: 2, failed: 3 }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :successful, -> { where(status: :completed) }
  scope :by_type, ->(type) { where(bill_type: type) }

  # Methods
  def formatted_amount
    "₵#{amount}"
  end

  def complete!
    update(status: :completed)
  end

  def fail!
    update(status: :failed)
  end
end
