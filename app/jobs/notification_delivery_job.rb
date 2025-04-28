class NotificationDeliveryJob < ApplicationJob
  queue_as :notifications
  
  # Retry with exponential backoff
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  
  # Process a notification delivery
  # @param delivery_id [Integer] ID of the NotificationDelivery to process
  def perform(delivery_id)
    delivery = NotificationDelivery.find_by(id: delivery_id)
    return unless delivery
    
    # Skip if already delivered or failed too many times
    return if delivery.status == 'delivered'
    return if delivery.status == 'failed' && delivery.attempts >= 3
    
    # Process the delivery
    delivery.process!
  end
end
