class LoanRepayment < ApplicationRecord
  belongs_to :loan
  belongs_to :payment_transaction, class_name: "Transaction", foreign_key: "transaction_id", optional: true

  enum :status, {
    pending: 0,
    successful: 1,
    failed: 2
  }

  validates :amount, presence: true, numericality: { greater_than: 0 }

  after_save :update_loan_status, if: :successful?

  private

  def update_loan_status
    # Check if loan is fully repaid
    if loan.current_balance <= 0
      loan.update(status: :completed)
    end
  end
end
