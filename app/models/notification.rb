class Notification < ApplicationRecord
  # Relationships
  belongs_to :user

  # Validations
  validates :title, presence: true
  validates :message, presence: true
  validates :severity, presence: true
  validates :category, presence: true

  # Enums
  enum :severity, {
    info: 0,
    warning: 1,
    critical: 2
  }, default: :info

  enum :category, {
    general: 0,
    security: 1,
    transaction: 2,
    account: 3,
    system: 4
  }, default: :general

  # Scopes
  scope :unread, -> { where(read: false) }
  scope :security, -> { where(category: :security) }
  scope :transactions, -> { where(category: :transaction) }
  scope :by_severity, ->(severity) { where(severity: severity) }
  scope :recent, -> { order(sent_at: :desc) }
  scope :recent_first, -> { order(sent_at: :desc) }
  scope :oldest_first, -> { order(sent_at: :asc) }

  # Instance methods

  # Mark notification as read
  # @return [Boolean] True if saved successfully
  def mark_as_read!
    update(read: true, read_at: Time.current)
  end

  # Mark notification as unread
  # @return [Boolean] True if saved successfully
  def mark_as_unread!
    update(read: false, read_at: nil)
  end

  # Get time ago in words for display
  # @return [String] Time ago in words
  def time_ago
    time_ago_in_words(sent_at) + " ago"
  end

  # Get CSS class for notification severity
  # @return [String] CSS class name
  def severity_class
    case severity.to_sym
    when :info then "info"
    when :warning then "warning"
    when :critical then "danger"
    else "info"
    end
  end

  # Get icon name for notification type
  # @return [String] Icon name
  def icon_name
    case category.to_sym
    when :security
      case severity.to_sym
      when :critical then "alert-octagon"
      when :warning then "alert-triangle"
      else "shield"
      end
    when :transaction then "credit-card"
    when :account then "user"
    when :system then "settings"
    else "bell"
    end
  end

  # Check if notification has an action URL
  # @return [Boolean] True if action URL is present
  def has_action?
    action_url.present?
  end

  # Get action button text
  # @return [String] Action button text
  def action_button_text
    action_text.presence || default_action_text
  end

  private

  # Get default action text based on category
  # @return [String] Default action text
  def default_action_text
    case category.to_sym
    when :security then "Review"
    when :transaction then "View"
    when :account then "Manage"
    else "View"
    end
  end
end
