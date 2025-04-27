class PaymentMethod < ApplicationRecord
  belongs_to :user

  # Virtual attribute for account number
  attr_accessor :account_number

  # Validations
  validates :method_type, presence: true
  validates :account_number, presence: true, on: :create
  validates :description, presence: true

  # Enums
  enum :method_type, {
    mobile_money: 0,
    bank: 1,
    card: 2,
    wallet: 3,
    other: 4
  }, default: :mobile_money

  enum :status, {
    pending: 0,
    verified: 1,
    rejected: 2,
    expired: 3
  }, default: :pending

  enum :verification_status, {
    pending_verification: 0,
    verification_approved: 1,
    verification_failed: 2
  }, default: :pending_verification

  # Callbacks
  before_save :encrypt_account_number, if: -> { account_number.present? }

  # Scopes
  scope :active_methods, -> { where.not(status: [ :rejected, :expired ]) }
  scope :verified_methods, -> { where(status: :verified) }
  scope :default_first, -> { order(default: :desc) }

  # Methods
  def verified?
    status == "verified"
  end

  def verification_approved?
    verification_status == "verification_approved"
  end

  def pending_verification?
    verification_status == "pending_verification"
  end

  def expired?
    return false unless expiry_date.present?

    # Convert string to date if needed
    date = expiry_date.is_a?(Date) ? expiry_date : parse_expiry_date
    date.present? && date < Date.current
  end

  # Format the expiry date as MM/YY
  def formatted_expiry_date
    return nil unless expiry_date.present?

    if expiry_date.is_a?(Date) || expiry_date.is_a?(Time)
      expiry_date.strftime("%m/%y")
    else
      # If it's already in MM/YY format, return as is
      if expiry_date.match?(/^\d{2}\/\d{2}$/)
        expiry_date
      else
        # Try to parse and format
        date = parse_expiry_date
        date ? date.strftime("%m/%y") : expiry_date
      end
    end
  end

  # Parse expiry date from string
  def parse_expiry_date
    return nil unless expiry_date.present?
    return expiry_date if expiry_date.is_a?(Date) || expiry_date.is_a?(Time)

    begin
      # Try different formats
      if expiry_date.match?(/^\d{2}\/\d{2}$/)
        # MM/YY format
        month, year = expiry_date.split("/")
        Date.new(2000 + year.to_i, month.to_i, 1).end_of_month
      else
        # Try standard date parsing
        Date.parse(expiry_date)
      end
    rescue
      nil
    end
  end

  def mark_as_used!
    update(last_used_at: Time.current)
  end

  def masked_account_number
    # If we have a masked_number stored, use that
    return masked_number if masked_number.present?

    # Otherwise, if we have the account_number, mask it
    return nil unless account_number

    # Different masking based on method type
    case method_type.to_s
    when "bank"
      # For bank accounts, show last 4 digits
      "•••• •••• " + account_number.last(4)
    when "card"
      # For cards, show last 4 digits
      "•••• •••• •••• " + account_number.last(4)
    when "mobile_money"
      # For mobile money, mask middle digits
      digits = account_number.size
      if digits > 4
        account_number.first(2) + "•" * (digits - 4) + account_number.last(2)
      else
        account_number
      end
    else
      # Generic masking for other types
      "•••• •••• " + account_number.last(4)
    end
  end

  def status_color
    case status
    when "verified"
      "green"
    when "pending"
      "yellow"
    when "rejected"
      "red"
    when "expired"
      "gray"
    end
  end

  def icon_name
    return "credit-card" if method_type.blank?

    case method_type.to_s
    when "bank"
      "bank"
    when "card"
      "credit-card"
    when "mobile_money"
      "smartphone"
    when "wallet"
      "wallet"
    else
      "credit-card"
    end
  end

  def method_type_color
    return "gray-500" if method_type.blank?

    case method_type.to_s
    when "bank"
      "blue-500"
    when "card"
      "purple-500"
    when "mobile_money"
      "green-500"
    when "wallet"
      "amber-500"
    else
      "gray-500"
    end
  end

  private

  # Encrypt the account number and store it in account_number_digest
  def encrypt_account_number
    require "bcrypt"
    self.account_number_digest = BCrypt::Password.create(account_number)
  end
end
