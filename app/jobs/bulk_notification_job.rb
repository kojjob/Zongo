class BulkNotificationJob < ApplicationJob
  queue_as :notifications
  
  # Send a notification to multiple users
  # @param user_ids [Array<Integer>] IDs of users to notify
  # @param notification_params [Hash] Notification parameters
  # @param channels [Array<Symbol>] Notification channels to use
  def perform(user_ids, notification_params, channels = [:in_app])
    # Find users
    users = User.where(id: user_ids)
    
    # Create notifications for each user
    users.each do |user|
      notification = user.notifications.create!(notification_params)
      notification.deliver_through(channels)
    end
  end
end
