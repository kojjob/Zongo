class LoanRefinancing < ApplicationRecord
  belongs_to :user
  belongs_to :original_loan, class_name: "Loan"
  belongs_to :new_loan, class_name: "Loan", optional: true

  # Validations
  validates :requested_amount, presence: true, numericality: { greater_than: 0 }
  validates :original_rate, presence: true, numericality: { greater_than: 0 }
  validates :requested_rate, presence: true, numericality: { greater_than: 0 }
  validates :term_days, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true

  # Enums
  enum :status, {
    pending: 0,
    approved: 1,
    rejected: 2,
    cancelled: 3
  }, default: :pending

  # Scopes
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  before_validation :set_defaults, on: :create

  # Calculate the savings amount
  def savings_amount
    return estimated_savings if estimated_savings.present?

    # Calculate if not already set
    original_interest = requested_amount * (original_rate / 100) * (term_days / 365.0)
    new_interest = requested_amount * (requested_rate / 100) * (term_days / 365.0)
    original_interest - new_interest
  end

  # Calculate the savings percentage
  def savings_percentage
    return 0 if original_rate.zero?
    ((original_rate - requested_rate) / original_rate * 100).round(2)
  end

  # Check if the refinancing will result in savings
  def has_savings?
    savings_amount > 0
  end

  # Get the status of the refinancing in a user-friendly format
  def status_text
    case status
    when "pending"
      "Pending Approval"
    when "approved"
      "Approved"
    when "rejected"
      "Rejected"
    when "cancelled"
      "Cancelled"
    else
      status.to_s.titleize
    end
  end

  # Get the new monthly payment amount
  def new_monthly_payment
    return 0 if requested_amount.zero? || term_days.zero?

    # Convert term_days to months
    term_months = (term_days / 30.0).ceil

    # Calculate monthly payment using the formula for equal installments
    monthly_rate = requested_rate / 100 / 12
    requested_amount * (monthly_rate * (1 + monthly_rate)**term_months) / ((1 + monthly_rate)**term_months - 1)
  end

  # Get the original monthly payment amount
  def original_monthly_payment
    return 0 if requested_amount.zero? || term_days.zero?

    # Convert term_days to months
    term_months = (term_days / 30.0).ceil

    # Calculate monthly payment using the formula for equal installments
    monthly_rate = original_rate / 100 / 12
    requested_amount * (monthly_rate * (1 + monthly_rate)**term_months) / ((1 + monthly_rate)**term_months - 1)
  end

  # Get the monthly savings amount
  def monthly_savings
    original_monthly_payment - new_monthly_payment
  end

  private

  # Set default values before validation
  def set_defaults
    self.status ||= :pending
    self.estimated_savings ||= savings_amount
  end
end
