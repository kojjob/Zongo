class Loan < ApplicationRecord
  belongs_to :user
  belongs_to :wallet
  has_many :loan_repayments, dependent: :destroy

  # Store credit score data, processing fee, and amount due as JSON in the metadata column if it exists
  # or use instance variables if the columns don't exist
  attr_accessor :_credit_score_data, :_processing_fee, :_amount_due

  enum :status, {
    pending: 0,
    approved: 1,
    disbursed: 2,
    active: 3,
    completed: 4,
    defaulted: 5,
    rejected: 6,
    cancelled: 7
  }

  enum :loan_type, {
    microloan: 0,
    emergency: 1,
    installment: 2,
    business: 3,
    agricultural: 4,
    salary_advance: 5
  }

  validates :amount, :interest_rate, :due_date, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :interest_rate, numericality: { greater_than_or_equal_to: 0 }

  # Validate that either term_days or term_months is present and valid
  validate :validate_term

  def validate_term
    if respond_to?(:term_days) && term_days.present?
      errors.add(:term_days, "must be greater than 0") unless term_days.to_i > 0
    elsif respond_to?(:term_months) && term_months.present?
      errors.add(:term_months, "must be greater than 0") unless term_months.to_i > 0
    else
      errors.add(:base, "Either term_days or term_months must be provided")
    end
  end

  before_create :generate_reference_number
  before_create :calculate_amount_due

  # Get term in days, converting from months if necessary
  def term_in_days
    return term_days if respond_to?(:term_days) && term_days.present?
    return term_months * 30 if respond_to?(:term_months) && term_months.present?
    0 # Default fallback
  end

  # Get processing fee safely
  def get_processing_fee
    return processing_fee if respond_to?(:processing_fee) && processing_fee.present?

    # If the attribute doesn't exist or is nil, calculate based on loan type
    fee_percentage = case loan_type
                     when 'microloan' then 0.01
                     when 'emergency' then 0.02
                     when 'installment' then 0.015
                     when 'business' then 0.02
                     when 'agricultural' then 0.01
                     when 'salary_advance' then 0.005
                     else 0.02 # default
                     end

    (amount * fee_percentage).round(2)
  end

  # Method to handle processing_fee attribute
  def processing_fee
    if respond_to?(:read_attribute) && has_attribute?(:processing_fee)
      read_attribute(:processing_fee)
    elsif respond_to?(:metadata) && metadata.present?
      metadata['processing_fee']
    else
      @_processing_fee
    end
  end

  # Method to set processing_fee attribute
  def processing_fee=(value)
    if respond_to?(:write_attribute) && has_attribute?(:processing_fee)
      write_attribute(:processing_fee, value)
    elsif respond_to?(:metadata=)
      self.metadata ||= {}
      self.metadata['processing_fee'] = value
    else
      @_processing_fee = value
    end
  end

  def calculate_amount_due
    # Simple interest calculation
    days = term_in_days
    interest_amount = (amount * interest_rate / 100) * (days / 365.0)
    fee_amount = get_processing_fee

    # Only set amount_due if the attribute exists
    if respond_to?(:amount_due=)
      self.amount_due = amount + interest_amount + fee_amount
    end

    # Return the calculated amount in any case
    amount + interest_amount + fee_amount
  end

  # Method to handle amount_due attribute
  def amount_due
    if respond_to?(:read_attribute) && has_attribute?(:amount_due)
      read_attribute(:amount_due)
    elsif respond_to?(:metadata) && metadata.present?
      metadata['amount_due']
    else
      @_amount_due
    end
  end

  # Method to set amount_due attribute
  def amount_due=(value)
    if respond_to?(:write_attribute) && has_attribute?(:amount_due)
      write_attribute(:amount_due, value)
    elsif respond_to?(:metadata=)
      self.metadata ||= {}
      self.metadata['amount_due'] = value
    else
      @_amount_due = value
    end
  end

  # Get amount due safely
  def get_amount_due
    return amount_due if amount_due.present?
    # Calculate on the fly if not stored
    days = term_in_days
    interest_amount = (amount * interest_rate / 100) * (days / 365.0)
    fee_amount = get_processing_fee
    amount + interest_amount + fee_amount
  end

  def current_balance
    return 0 if completed?

    # Use stored current_balance if available
    return self[:current_balance] if respond_to?(:current_balance) && self[:current_balance].present?

    # Otherwise calculate
    total_due = get_amount_due
    return total_due if loan_repayments.none?

    total_due - loan_repayments.where(status: :successful).sum(:amount)
  end

  def overdue?
    active? && due_date < Time.current
  end

  def days_overdue
    return 0 unless overdue?
    (Time.current.to_date - due_date.to_date).to_i
  end

  # Method to store credit score data
  # @param data [Hash] Credit score data to store
  def credit_score_data=(data)
    if respond_to?(:metadata=)
      # Store in metadata column if it exists
      self.metadata ||= {}
      self.metadata['credit_score_data'] = data
    else
      # Otherwise use instance variable
      @_credit_score_data = data
    end
  end

  # Method to retrieve credit score data
  # @return [Hash, nil] The stored credit score data or nil if not set
  def credit_score_data
    if respond_to?(:metadata) && metadata.present?
      # Retrieve from metadata column if it exists
      metadata['credit_score_data']
    else
      # Otherwise use instance variable
      @_credit_score_data
    end
  end

  def repayment_schedule
    return [] unless disbursed? || active?

    # For installment loans, calculate periodic payments
    if installment?
      # Calculate number of installments based on term_in_days
      days = term_in_days
      num_installments = [ days / 30, 1 ].max
      total_due = get_amount_due
      installment_amount = (total_due / num_installments).round(2)

      # Generate schedule
      schedule = []
      num_installments.times do |i|
        installment_date = disbursed_at + ((i + 1) * (days / num_installments)).days

        # For the last installment, ensure we collect the full amount (accounting for rounding)
        is_last = i == num_installments - 1
        amount = is_last ? (total_due - (installment_amount * i)) : installment_amount

        schedule << {
          installment_number: i + 1,
          due_date: installment_date,
          amount: amount,
          status: determine_installment_status(installment_date)
        }
      end

      schedule
    else
      # For other loans, single payment at due date
      [ {
        installment_number: 1,
        due_date: due_date,
        amount: get_amount_due,
        status: determine_installment_status(due_date)
      } ]
    end
  end

  private

  def determine_installment_status(date)
    return "paid" if completed?

    if date < Time.current
      "overdue"
    else
      "upcoming"
    end
  end

  def generate_reference_number
    loop do
      self.reference_number = "LOAN-#{SecureRandom.alphanumeric(8).upcase}"
      break unless Loan.exists?(reference_number: reference_number)
    end
  end
end
