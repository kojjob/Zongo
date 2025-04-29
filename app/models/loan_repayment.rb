class LoanRepayment < ApplicationRecord
  belongs_to :loan
  belongs_to :payment_transaction, class_name: "Transaction", foreign_key: "transaction_id", optional: true

  enum :status, {
    pending: 0,
    successful: 1,
    failed: 2
  }, default: :pending

  validates :amount, presence: true, numericality: { greater_than: 0 }

  after_save :update_loan_status, if: :successful?

  # Ensure principal_portion returns a value
  def principal_portion
    self[:principal_portion] || principal_amount
  end

  # Ensure interest_portion returns a value
  def interest_portion
    self[:interest_portion] || interest_amount
  end

  # Ensure fee_portion returns a value
  def fee_portion
    self[:fee_portion] || 0
  end

  # Ensure remaining_balance returns a value
  def remaining_balance
    self[:remaining_balance] || (loan&.current_balance || 0)
  end

  private

  def update_loan_status
    # Check if loan is fully repaid
    if loan.current_balance <= 0
      loan.update(status: :completed)
    end
  end
end
