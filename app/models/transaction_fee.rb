class TransactionFee < ApplicationRecord
  # Validations
  validates :name, presence: true
  validates :transaction_type, presence: true
  validates :fee_type, presence: true
  validates :fixed_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :min_fee, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :max_fee, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :validate_fee_configuration

  # Enums
  enum :transaction_type, {
    deposit: 0,
    withdrawal: 1,
    transfer: 2,
    payment: 3,
    all: 4 # Applies to all transaction types
  }, default: :all

  enum :fee_type, {
    fixed: 0,      # Fixed amount fee
    percentage: 1, # Percentage of transaction amount
    hybrid: 2      # Percentage with min/max limits
  }, default: :fixed

  # Scopes
  scope :active, -> { where(active: true) }
  scope :for_transaction_type, ->(type) {
    where("transaction_type = ? OR transaction_type = ?", TransactionFee.transaction_types[type], TransactionFee.transaction_types[:all])
  }

  # Calculate fee for a given amount
  # @param amount [Decimal] The transaction amount
  # @return [Decimal] The calculated fee
  def calculate_fee(amount)
    return 0 unless active?

    case fee_type.to_sym
    when :fixed
      fixed_amount || 0
    when :percentage
      calculated = amount * (percentage || 0) / 100
      calculated.round(2)
    when :hybrid
      calculated = amount * (percentage || 0) / 100

      # Apply minimum fee if set
      calculated = [ calculated, min_fee || 0 ].max if min_fee.present?

      # Apply maximum fee if set
      calculated = [ calculated, max_fee || Float::INFINITY ].min if max_fee.present?

      calculated.round(2)
    else
      0
    end
  end

  # Class method to find applicable fee for a transaction
  # @param transaction_type [Symbol, String] The type of transaction
  # @param amount [Decimal] The transaction amount
  # @return [Decimal] The calculated fee
  def self.calculate_fee_for(transaction_type, amount)
    # Find active fees for this transaction type (or general fees)
    applicable_fees = active.for_transaction_type(transaction_type)

    # If no fees configured, return 0
    return 0 if applicable_fees.empty?

    # Use the first applicable fee (in the future, could implement more complex fee selection logic)
    applicable_fees.first.calculate_fee(amount)
  end

  private

  # Validate that the fee configuration is valid based on fee_type
  def validate_fee_configuration
    case fee_type.to_sym
    when :fixed
      errors.add(:fixed_amount, "must be present for fixed fee type") if fixed_amount.blank?
    when :percentage
      errors.add(:percentage, "must be present for percentage fee type") if percentage.blank?
    when :hybrid
      errors.add(:percentage, "must be present for hybrid fee type") if percentage.blank?

      # For hybrid, either min or max (or both) should be set
      if min_fee.blank? && max_fee.blank?
        errors.add(:base, "Either minimum fee or maximum fee must be set for hybrid fee type")
      end

      # If both min and max are set, max should be greater than min
      if min_fee.present? && max_fee.present? && max_fee < min_fee
        errors.add(:max_fee, "must be greater than minimum fee")
      end
    end
  end
end
