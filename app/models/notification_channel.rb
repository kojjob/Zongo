class NotificationChannel < ApplicationRecord
  # Relationships
  belongs_to :user
  has_many :notification_deliveries, dependent: :destroy
  has_many :notifications, through: :notification_deliveries

  # Validations
  validates :channel_type, presence: true
  validates :identifier, presence: true
  validates :identifier, uniqueness: { scope: :channel_type }

  # Scopes
  scope :enabled, -> { where(enabled: true) }
  scope :verified, -> { where(verified: true) }
  scope :by_type, ->(type) { where(channel_type: type) }
  scope :email, -> { where(channel_type: 'email') }
  scope :sms, -> { where(channel_type: 'sms') }
  scope :push, -> { where(channel_type: 'push') }

  # Callbacks
  before_create :generate_verification_token, if: -> { verification_token.blank? }

  # Instance methods

  # Mark channel as verified
  # @return [Boolean] True if saved successfully
  def verify!
    update(verified: true, verified_at: Time.current)
  end

  # Generate and send verification code
  # @return [Boolean] True if verification was sent successfully
  def send_verification
    return false if verification_sent_at && verification_sent_at > 5.minutes.ago
    
    generate_verification_token
    self.verification_sent_at = Time.current
    self.verification_attempts = 0
    
    if save
      # Send verification based on channel type
      case channel_type
      when 'email'
        NotificationMailer.verify_email(self).deliver_later
      when 'sms'
        SmsService.send_verification(identifier, verification_token)
      when 'push'
        # Push verification is handled differently
        true
      else
        false
      end
    else
      false
    end
  end

  # Verify channel with token
  # @param token [String] Verification token
  # @return [Boolean] True if verification was successful
  def verify_with_token(token)
    return false if verified?
    return false if verification_token.blank?
    return false if verification_attempts >= 3
    
    self.verification_attempts += 1
    
    if verification_token == token
      verify!
    else
      save
      false
    end
  end

  # Check if channel can receive notifications of a specific category and severity
  # @param category [Symbol] Notification category
  # @param severity [Symbol] Notification severity
  # @return [Boolean] True if channel can receive notifications
  def can_receive?(category, severity)
    return false unless enabled?
    return false unless verified?
    
    # Get user preferences for this channel type
    preferences = user.notification_preferences&.send("#{channel_type}_preferences") || {}
    
    # Check if this category and severity is enabled
    category_prefs = preferences[category.to_s] || {}
    category_prefs[severity.to_s] || false
  end

  private

  # Generate a verification token
  def generate_verification_token
    self.verification_token = SecureRandom.alphanumeric(6).upcase
  end
end
