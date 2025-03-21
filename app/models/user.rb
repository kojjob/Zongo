class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable, :lockable,
         :timeoutable, :trackable, :recoverable, :rememberable, :validatable

  # Relationships
  has_one_attached :avatar
  # has_one :profile, dependent: :destroy
  has_one :wallet, dependent: :destroy
  has_one :setting, class_name: 'UserSetting', dependent: :destroy

  # has_many :devices, dependent: :destroy
  # has_many :verification_attempts, dependent: :destroy
  has_many :payment_methods, dependent: :destroy
  has_many :outgoing_transactions, through: :wallet, source: :outgoing_transactions
  has_many :incoming_transactions, through: :wallet, source: :incoming_transactions

  # Enums
  enum :kyc_level, { basic: 0, intermediate: 1, full: 2 }
  enum :status, { pending: 0, active: 1, suspended: 2, locked: 3 }

  # Callbacks
  # after_create :create_profile
  after_create :create_wallet
  after_create :create_default_setting


  # Validations
  validates :phone, presence: true, uniqueness: true
  # Username validations
  validates :username, presence: true, uniqueness: { case_sensitive: false }, allow_blank: true
  validates :username, format: { with: /\A[a-zA-Z0-9_\.]+\z/, message: "only allows letters, numbers, dots and underscore" }, if: -> { username.present? }
  validates :username, length: { minimum: 3, maximum: 30 }, if: -> { username.present? }

  validate :acceptable_avatar

  # Fallback to default avatar if none is provided
  before_validation :normalize_username

  # Instance methods
  def verified?
    phone_verified_at.present?
  end

  def can_transact?
    active? && verified?
  end
  validate :acceptable_avatar, if: -> { avatar.attached? }

  def acceptable_avatar
    # Check file size
    if avatar.blob.byte_size > 5.megabytes
      errors.add(:avatar, "is too large (maximum size is 5MB)")
      avatar.purge
    end

    # Check file type
    acceptable_types = [ "image/jpeg", "image/png", "image/gif" ]
    unless acceptable_types.include?(avatar.content_type)
      errors.add(:avatar, "must be a JPEG, PNG, or GIF")
      avatar.purge
    end
  end

  # Helper method for displaying user's name or username
  def display_name
    username.presence || phone
  end

  # Helper method for generating initials for avatar placeholder
  def initials
    if username.present?
      username[0..1].upcase
    else
      phone[0..1]
    end
  end

  # def update_kyc_level
  #   if profile.intermediate_kyc_complete?
  #     update(kyc_level: :intermediate)
  #   elsif profile.full_kyc_complete?
  #     update(kyc_level: :full)
  #   end
  # end

  def acceptable_avatar
    return unless avatar.attached?

    # Check file size
    errors.add(:avatar, "is too large (max 5MB)") unless avatar.blob.byte_size <= 5.megabytes

    # Check file type
    acceptable_types = [ "image/jpeg", "image/png" ]
    errors.add(:avatar, "must be a JPEG or PNG") unless acceptable_types.include?(avatar.content_type)
  end

  private
   def normalize_username
    self.username = username.to_s.downcase.strip if username
  end

  # def create_profile
  #   build_profile.save
  # end

  def create_wallet
    build_wallet(wallet_id: "W#{SecureRandom.alphanumeric(12).upcase}", status: :active).save
  end

  def create_default_setting
    create_setting unless setting
  end
end
