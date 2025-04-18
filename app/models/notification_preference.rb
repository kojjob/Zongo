class NotificationPreference < ApplicationRecord
  # Relationships
  belongs_to :user

  # Validations
  validates :user_id, presence: true, uniqueness: true

  # Default preferences
  after_initialize :set_default_preferences

  # Serialize preferences
  serialize :email_preferences, Hash
  serialize :sms_preferences, Hash
  serialize :push_preferences, Hash

  # Class methods

  # Create default preferences for a user
  # @param user [User] User to create preferences for
  # @return [NotificationPreference] Created preferences
  def self.create_defaults_for(user)
    create!(
      user: user,
      email_preferences: default_email_preferences,
      sms_preferences: default_sms_preferences,
      push_preferences: default_push_preferences
    )
  end

  # Default email preferences
  # @return [Hash] Default email preferences
  def self.default_email_preferences
    {
      security: {
        info: true,
        warning: true,
        critical: true
      },
      transaction: {
        info: true,
        warning: true,
        critical: true
      },
      account: {
        info: true,
        warning: true,
        critical: true
      },
      system: {
        info: false,
        warning: true,
        critical: true
      },
      general: {
        info: false,
        warning: true,
        critical: true
      }
    }
  end

  # Default SMS preferences
  # @return [Hash] Default SMS preferences
  def self.default_sms_preferences
    {
      security: {
        info: false,
        warning: true,
        critical: true
      },
      transaction: {
        info: false,
        warning: true,
        critical: true
      },
      account: {
        info: false,
        warning: false,
        critical: true
      },
      system: {
        info: false,
        warning: false,
        critical: true
      },
      general: {
        info: false,
        warning: false,
        critical: true
      }
    }
  end

  # Default push preferences
  # @return [Hash] Default push preferences
  def self.default_push_preferences
    {
      security: {
        info: false,
        warning: true,
        critical: true
      },
      transaction: {
        info: true,
        warning: true,
        critical: true
      },
      account: {
        info: false,
        warning: true,
        critical: true
      },
      system: {
        info: false,
        warning: false,
        critical: true
      },
      general: {
        info: false,
        warning: false,
        critical: true
      }
    }
  end

  # Instance methods

  # Check if email notifications are enabled for a category and severity
  # @param category [Symbol] Notification category
  # @param severity [Symbol] Notification severity
  # @return [Boolean] True if enabled
  def email_enabled_for?(category, severity)
    category = category.to_s
    severity = severity.to_s

    return false unless email_preferences.key?(category)
    return false unless email_preferences[category].key?(severity)

    email_preferences[category][severity]
  end

  # Check if SMS notifications are enabled for a category and severity
  # @param category [Symbol] Notification category
  # @param severity [Symbol] Notification severity
  # @return [Boolean] True if enabled
  def sms_enabled_for?(category, severity)
    category = category.to_s
    severity = severity.to_s

    return false unless sms_preferences.key?(category)
    return false unless sms_preferences[category].key?(severity)

    sms_preferences[category][severity]
  end

  # Check if push notifications are enabled for a category and severity
  # @param category [Symbol] Notification category
  # @param severity [Symbol] Notification severity
  # @return [Boolean] True if enabled
  def push_enabled_for?(category, severity)
    category = category.to_s
    severity = severity.to_s

    return false unless push_preferences.key?(category)
    return false unless push_preferences[category].key?(severity)

    push_preferences[category][severity]
  end

  # Update email preferences
  # @param category [Symbol] Notification category
  # @param severity [Symbol] Notification severity
  # @param enabled [Boolean] Whether to enable or disable
  # @return [Boolean] True if saved successfully
  def update_email_preference(category, severity, enabled)
    category = category.to_s
    severity = severity.to_s

    # Ensure category and severity exist in preferences
    email_preferences[category] ||= {}
    email_preferences[category][severity] = enabled

    save
  end

  # Update SMS preferences
  # @param category [Symbol] Notification category
  # @param severity [Symbol] Notification severity
  # @param enabled [Boolean] Whether to enable or disable
  # @return [Boolean] True if saved successfully
  def update_sms_preference(category, severity, enabled)
    category = category.to_s
    severity = severity.to_s

    # Ensure category and severity exist in preferences
    sms_preferences[category] ||= {}
    sms_preferences[category][severity] = enabled

    save
  end

  # Update push preferences
  # @param category [Symbol] Notification category
  # @param severity [Symbol] Notification severity
  # @param enabled [Boolean] Whether to enable or disable
  # @return [Boolean] True if saved successfully
  def update_push_preference(category, severity, enabled)
    category = category.to_s
    severity = severity.to_s

    # Ensure category and severity exist in preferences
    push_preferences[category] ||= {}
    push_preferences[category][severity] = enabled

    save
  end

  private

  # Set default preferences
  def set_default_preferences
    self.email_preferences ||= self.class.default_email_preferences
    self.sms_preferences ||= self.class.default_sms_preferences
    self.push_preferences ||= self.class.default_push_preferences
  end
end
