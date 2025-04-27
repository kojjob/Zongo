class SecurityLog < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :loggable, polymorphic: true, optional: true

  # Validations
  validates :event_type, presence: true
  validates :severity, presence: true

  # Enums
  enum :event_type, {
    login_attempt: 0,
    login_success: 1,
    login_failure: 2,
    password_change: 3,
    account_locked: 4,
    transaction_check: 5,
    transaction_blocked: 6,
    suspicious_activity: 7,
    ip_change: 8,
    device_change: 9,
    verification_success: 10,
    verification_failure: 11
  }, default: :login_attempt

  enum :severity, {
    info: 0,
    warning: 1,
    critical: 2
  }, default: :info

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :critical, -> { where(severity: :critical) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :transaction_related, -> { where(event_type: [ :transaction_check, :transaction_blocked ]) }

  # Check if the user has had suspicious activity recently
  # @param user_id [Integer] The user ID to check
  # @return [Boolean] True if suspicious activity has been detected recently
  def self.recent_suspicious_activity?(user_id)
    where(user_id: user_id)
      .where(severity: [ :warning, :critical ])
      .where("created_at > ?", 24.hours.ago)
      .exists?
  end

  # Check if there have been multiple failed login attempts
  # @param user_id [Integer] The user ID to check
  # @return [Boolean] True if multiple failed login attempts have been detected
  def self.multiple_failed_logins?(user_id)
    where(user_id: user_id)
      .where(event_type: :login_failure)
      .where("created_at > ?", 30.minutes.ago)
      .count >= 3
  end

  # Log a security event
  # @param user [User] The user associated with the event
  # @param event_type [Symbol] The type of event
  # @param severity [Symbol] The severity level
  # @param details [Hash] Additional details about the event
  # @param ip_address [String] The IP address associated with the event
  # @param user_agent [String] The user agent associated with the event
  # @param loggable [ActiveRecord] The associated record (e.g., Transaction)
  # @return [SecurityLog] The created security log
  def self.log_event(user, event_type, severity: :info, details: {}, ip_address: nil, user_agent: nil, loggable: nil)
    create(
      user: user,
      event_type: event_type,
      severity: severity,
      details: details,
      ip_address: ip_address,
      user_agent: user_agent,
      loggable: loggable
    )
  end
end
