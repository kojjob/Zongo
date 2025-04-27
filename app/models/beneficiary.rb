class Beneficiary < ApplicationRecord
  # Relationships
  belongs_to :user
  has_one_attached :avatar

  # Validations
  validates :name, presence: true
  validates :account_number, presence: true
  validates :bank_name, presence: true, unless: :is_wallet_transfer?
  validates :phone_number, presence: true, if: :is_mobile_money?
  # Ensure each user can only have one beneficiary with a specific account number
  validates :account_number, uniqueness: { scope: :user_id }



  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :frequently_used, -> { order(usage_count: :desc) }

  # Enums
  enum :transfer_type, { bank: 0, mobile_money: 1, wallet: 2 }, default: :bank

  # Methods
  def increment_usage!
    update(usage_count: usage_count + 1, last_used_at: Time.current)
  end

  def is_mobile_money?
    transfer_type == "mobile_money"
  end

  def is_wallet_transfer?
    transfer_type == "wallet"
  end
end
