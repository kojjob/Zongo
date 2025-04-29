class Notification < ApplicationRecord
  # Relationships
  belongs_to :user
  has_many :notification_deliveries, dependent: :destroy
  has_many :notification_channels, through: :notification_deliveries

  # Validations
  validates :title, presence: true
  validates :message, presence: true
  validates :severity, presence: true
  validates :category, presence: true

  # Callbacks
  before_create :set_sent_at

  # Enums
  enum :severity, {
    info: 0,
    warning: 1,
    critical: 2
  }, default: :info

  enum :category, {
    general: 0,
    security: 1,
    financial: 2,
    account: 3,
    system: 4,
    loan: 5,
    payment: 6,
    event: 7,
    marketplace: 8
  }, default: :general

  # Scopes
  scope :unread, -> { where(read: false) }
  scope :security, -> { where(category: :security) }
  scope :financial, -> { where(category: :financial) }
  scope :loan, -> { where(category: :loan) }
  scope :by_category, ->(category) { where(category: category) }
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

  # Get icon name for notification category
  # @return [String] Icon name
  def icon_name
    case category.to_sym
    when :security
      case severity.to_sym
      when :critical then "alert-octagon"
      when :warning then "alert-triangle"
      else "shield"
      end
    when :financial then "credit-card"
    when :account then "user"
    when :system then "settings"
    when :loan then "dollar-sign"
    when :payment then "credit-card"
    when :event then "calendar"
    when :marketplace then "shopping-bag"
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

  # Deliver notification through specified channels
  # @param channels [Array<Symbol>] List of channel types to deliver through (:email, :sms, :push)
  # @return [Array<NotificationDelivery>] Created delivery records
  def deliver_through(channels = [:in_app])
    return [] unless user

    deliveries = []

    channels.each do |channel_type|
      next if channel_type == :in_app # In-app is always delivered

      # Find enabled channels of this type for the user
      user_channels = user.notification_channels.where(channel_type: channel_type, enabled: true)

      user_channels.each do |channel|
        # Create delivery record
        delivery = notification_deliveries.create!(
          notification_channel: channel,
          status: 'pending'
        )

        # Queue delivery job if the job exists
        if defined?(NotificationDeliveryJob)
          NotificationDeliveryJob.perform_later(delivery.id)
        else
          Rails.logger.info "NotificationDeliveryJob not defined, skipping delivery for notification #{id}"
        end

        deliveries << delivery
      end
    end

    # Broadcast in-app notification
    broadcast_to_user if channels.include?(:in_app)

    deliveries
  end

  # Broadcast notification to user via ActionCable
  def broadcast_to_user
    return unless user

    # Broadcast notification to user's channel
    NotificationsChannel.broadcast_to(
      user,
      {
        id: id,
        title: title,
        message: message,
        severity: severity,
        category: category,
        action_url: action_url,
        action_text: action_button_text,
        icon: icon_name,
        sent_at: sent_at.iso8601,
        created_at: created_at.iso8601,
        html: ApplicationController.render(
          partial: 'notifications/notification',
          locals: { notification: self }
        )
      }
    )
  end

  private

  # Set sent_at timestamp
  def set_sent_at
    self.sent_at ||= Time.current
  end

  # Get default action text based on category
  # @return [String] Default action text
  def default_action_text
    case category.to_sym
    when :security then "Review"
    when :financial then "View"
    when :account then "Manage"
    else "View"
    end
  end
end
