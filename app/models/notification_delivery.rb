class NotificationDelivery < ApplicationRecord
  # Relationships
  belongs_to :notification
  belongs_to :notification_channel

  # Validations
  validates :status, presence: true

  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :delivered, -> { where(status: 'delivered') }
  scope :failed, -> { where(status: 'failed') }
  scope :by_channel_type, ->(type) { joins(:notification_channel).where(notification_channels: { channel_type: type }) }

  # Delegate methods to notification and channel
  delegate :user, to: :notification
  delegate :channel_type, :identifier, to: :notification_channel

  # Instance methods

  # Mark delivery as delivered
  # @return [Boolean] True if saved successfully
  def mark_as_delivered!
    update(status: 'delivered', delivered_at: Time.current)
  end

  # Mark delivery as failed with error message
  # @param error [String] Error message
  # @return [Boolean] True if saved successfully
  def mark_as_failed!(error = nil)
    update(
      status: 'failed',
      error_message: error,
      attempts: attempts + 1
    )
  end

  # Mark delivery as read
  # @return [Boolean] True if saved successfully
  def mark_as_read!
    update(read_at: Time.current)
  end

  # Check if delivery can be retried
  # @return [Boolean] True if delivery can be retried
  def can_retry?
    status == 'failed' && attempts < 3
  end

  # Retry delivery
  # @return [Boolean] True if retry was queued successfully
  def retry!
    return false unless can_retry?
    
    update(status: 'pending')
    NotificationDeliveryJob.perform_later(id)
    true
  end

  # Process delivery
  # @return [Boolean] True if delivery was successful
  def process!
    return false unless status == 'pending'
    
    begin
      case channel_type
      when 'email'
        process_email_delivery
      when 'sms'
        process_sms_delivery
      when 'push'
        process_push_delivery
      else
        mark_as_failed!("Unsupported channel type: #{channel_type}")
        return false
      end
      
      mark_as_delivered!
      true
    rescue => e
      mark_as_failed!(e.message)
      false
    end
  end

  private

  # Process email delivery
  def process_email_delivery
    NotificationMailer.send_notification(self).deliver_now
  end

  # Process SMS delivery
  def process_sms_delivery
    SmsService.send_notification(
      identifier,
      notification.title,
      notification.message
    )
  end

  # Process push delivery
  def process_push_delivery
    PushNotificationService.send_notification(
      identifier,
      notification.title,
      notification.message,
      {
        action_url: notification.action_url,
        category: notification.category,
        severity: notification.severity,
        metadata: notification.metadata
      }
    )
  end
end
