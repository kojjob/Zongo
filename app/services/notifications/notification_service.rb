module Notifications
  class NotificationService
    # Sends a notification via multiple channels depending on severity, user preferences, etc.
    # @param user [User] The user to notify
    # @param title [String] Notification title
    # @param message [String] Notification message
    # @param severity [Symbol] :info, :warning, or :critical
    # @param category [Symbol] e.g. :security, :transaction, :account
    # @param action_url [String] Optional URL for action button
    # @param action_text [String] Optional text for action button
    # @param metadata [Hash] Additional data related to the notification
    # @return [Notification] The created notification object
    def self.notify(user:, title:, message:, severity: :info, category: :general,
                   action_url: nil, action_text: nil, metadata: {})
      # Create in-app notification record
      notification = create_notification(
        user: user,
        title: title,
        message: message,
        severity: severity,
        category: category,
        action_url: action_url,
        action_text: action_text,
        metadata: metadata
      )

      # Determine which notification methods to use based on severity and user preferences
      methods = notification_methods(user, severity, category)

      # Send notifications through appropriate channels
      methods.each do |method|
        case method
        when :in_app
          # In-app notification already created above
          broadcast_in_app_notification(notification)
        when :email
          send_email_notification(notification)
        when :sms
          send_sms_notification(notification)
        when :push
          send_push_notification(notification)
        end
      end

      # Return the created notification
      notification
    end

    # Creates a notification record in the database
    # @return [Notification] The created notification
    def self.create_notification(user:, title:, message:, severity:, category:,
                               action_url:, action_text:, metadata:)
      Notification.create!(
        user: user,
        title: title,
        message: message,
        severity: severity,
        category: category,
        action_url: action_url,
        action_text: action_text,
        metadata: metadata,
        read: false,
        sent_at: Time.current
      )
    end

    # Broadcasts an in-app notification using Turbo Streams
    def self.broadcast_in_app_notification(notification)
      # Use Turbo Streams to push notification to the user's browser
      Turbo::StreamsChannel.broadcast_append_to(
        "user_notifications_#{notification.user_id}",
        target: "notifications_list",
        partial: "notifications/notification",
        locals: { notification: notification }
      )

      # Also broadcast an update to the notifications count
      unread_count = Notification.where(user_id: notification.user_id, read: false).count
      Turbo::StreamsChannel.broadcast_replace_to(
        "user_notifications_#{notification.user_id}",
        target: "notifications_count",
        html: unread_count.to_s
      )

      # For critical alerts, show a toast notification
      if notification.severity == "critical"
        Turbo::StreamsChannel.broadcast_append_to(
          "user_notifications_#{notification.user_id}",
          target: "notification_toasts",
          partial: "notifications/toast",
          locals: { notification: notification }
        )
      end
    end

    # Sends email notification
    def self.send_email_notification(notification)
      # Queue email delivery
      NotificationMailer.security_alert(
        notification.user,
        notification.title,
        notification.message,
        notification.action_url,
        notification.metadata
      ).deliver_later
    end

    # Sends SMS notification
    def self.send_sms_notification(notification)
      # Only send SMS for certain types of notifications
      return unless notification.severity.to_sym == :critical ||
                   (notification.category.to_sym == :security && notification.severity.to_sym == :warning)

      # Get user's phone number
      phone = notification.user.phone
      return if phone.blank?

      # Format message for SMS (keep it short)
      sms_message = "#{notification.title}: #{notification.message}"

      # Use SMS service to send message
      # This is placeholder code - integrate with your SMS provider
      begin
        SmsService.send_message(
          to: phone,
          message: sms_message
        )
      rescue => e
        Rails.logger.error("Failed to send SMS notification: #{e.message}")
      end
    end

    # Sends push notification
    def self.send_push_notification(notification)
      # Check if user has push tokens
      return unless notification.user.push_tokens.exists?

      # Use web push or mobile push depending on device
      notification.user.push_tokens.each do |token|
        case token.device_type
        when "web"
          send_web_push(token, notification)
        when "ios", "android"
          send_mobile_push(token, notification)
        end
      end
    end

    private

    # Determine which notification methods to use based on severity and user preferences
    def self.notification_methods(user, severity, category)
      methods = [ :in_app ] # Always use in-app notifications

      # Always use email for critical security alerts regardless of preferences
      if severity == :critical || (category == :security && severity == :warning)
        methods << :email

        # Add SMS for critical security alerts if the user has a phone
        methods << :sms if user.phone.present?

        # Add push notification if available
        methods << :push if user.push_tokens.exists?
      else
        # For non-critical alerts, respect user preferences

        # Check if user wants email notifications for this category and severity
        if user.notification_preferences.email_enabled_for?(category, severity)
          methods << :email
        end

        # Check if user wants SMS notifications for this category and severity
        if user.notification_preferences.sms_enabled_for?(category, severity) && user.phone.present?
          methods << :sms
        end

        # Check if user wants push notifications for this category and severity
        if user.notification_preferences.push_enabled_for?(category, severity) && user.push_tokens.exists?
          methods << :push
        end
      end

      methods
    end

    # Send web push notification
    def self.send_web_push(token, notification)
      # This is placeholder code - integrate with your web push provider
      begin
        WebPushService.send_notification(
          subscription: token.token,
          title: notification.title,
          body: notification.message,
          icon: "/assets/icons/notification-icon.png",
          data: {
            url: notification.action_url,
            notification_id: notification.id
          }
        )
      rescue => e
        Rails.logger.error("Failed to send web push notification: #{e.message}")
      end
    end

    # Send mobile push notification
    def self.send_mobile_push(token, notification)
      # This is placeholder code - integrate with your mobile push provider (FCM, APNS, etc.)
      begin
        MobilePushService.send_notification(
          token: token.token,
          platform: token.device_type,
          title: notification.title,
          body: notification.message,
          data: {
            notification_id: notification.id,
            action_url: notification.action_url
          }
        )
      rescue => e
        Rails.logger.error("Failed to send mobile push notification: #{e.message}")
      end
    end
  end
end
