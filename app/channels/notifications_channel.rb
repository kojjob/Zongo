class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    # Only allow authenticated users to subscribe to their own notifications
    return reject unless current_user
    
    # Stream notifications for this user
    stream_for current_user
    
    # Mark user as online
    current_user.update_column(:last_seen_at, Time.current) if current_user.respond_to?(:last_seen_at)
    
    # Send initial unread count
    transmit({ 
      type: 'unread_count', 
      count: current_user.unread_notifications_count 
    })
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    stop_all_streams
  end
  
  # Mark a notification as read
  def mark_as_read(data)
    notification_id = data['id']
    notification = current_user.notifications.find_by(id: notification_id)
    
    if notification && !notification.read?
      notification.mark_as_read!
      
      # Broadcast updated unread count
      transmit({ 
        type: 'unread_count', 
        count: current_user.unread_notifications_count 
      })
    end
  end
  
  # Mark all notifications as read
  def mark_all_as_read
    count = current_user.mark_all_notifications_as_read!
    
    # Broadcast updated unread count
    transmit({ 
      type: 'unread_count', 
      count: 0,
      marked_count: count
    })
  end
end
