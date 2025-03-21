class PaymentMethod < ApplicationRecord
  belongs_to :user

  # Validations
  validates :method_type, presence: true
  validates :account_number, presence: true
  validates :description, presence: true

  # Enums
  enum :status, {
    pending: 0,
    verified: 1,
    rejected: 2,
    expired: 3
  }, default: :pending

  # Scopes
  scope :active_methods, -> { where.not(status: [:rejected, :expired]) }
  scope :verified_methods, -> { where(status: :verified) }
  scope :default_first, -> { order(default: :desc) }

  # Methods
  def verified?
    status == 'verified' && verified_at.present?
  end

  def expired?
    expiry_date.present? && expiry_date < Date.current
  end

  def mark_as_used!
    update(last_used_at: Time.current)
  end

  def masked_account_number
    return nil unless account_number
    
    # Different masking based on method type
    case method_type
    when 'bank'
      # For bank accounts, show last 4 digits
      "•••• •••• " + account_number.last(4)
    when 'card'
      # For cards, show last 4 digits
      "•••• •••• •••• " + account_number.last(4)
    when 'mobile_money'
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
    when 'verified'
      'green'
    when 'pending'
      'yellow'
    when 'rejected'
      'red'
    when 'expired'
      'gray'
    end
  end

  def icon_name
    return 'credit-card' if method_type.blank?
    
    case method_type
    when 'bank'
      'bank'
    when 'card'
      'credit-card'
    when 'mobile_money'
      'smartphone'
    when 'wallet'
      'wallet'
    else
      'credit-card'
    end
  end
end
