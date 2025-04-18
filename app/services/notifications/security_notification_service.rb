module Notifications
  class SecurityNotificationService
    # Send notification for a blocked transaction
    # @param transaction [Transaction] The blocked transaction
    # @param reason [String] The reason for blocking
    # @return [Notification] The created notification
    def self.blocked_transaction(transaction)
      user = transaction.source_wallet&.user || transaction.destination_wallet&.user

      return nil if user.nil?

      # Get reason from transaction metadata
      reasons = transaction.metadata.dig("security_check", "reasons") if transaction.metadata.present?
      reason_text = if reasons.present? && reasons.is_a?(Array) && reasons.any?
                      reasons.join(", ")
      else
                      "Suspicious activity detected"
      end

      # Format amount
      amount_text = "#{transaction.formatted_amount} via #{transaction.payment_method.titleize}"

      # Create notification
      NotificationService.notify(
        user: user,
        title: "Transaction Blocked",
        message: "#{transaction.transaction_type.titleize} for #{amount_text} was blocked: #{reason_text}",
        severity: :warning,
        category: :security,
        action_url: transactions_wallet_path(status: "blocked"),
        action_text: "View Details",
        metadata: {
          transaction_id: transaction.id,
          transaction_type: transaction.transaction_type,
          amount: transaction.amount,
          formatted_amount: transaction.formatted_amount,
          reason: reason_text
        }
      )
    end

    # Send notification for suspicious activity
    # @param user [User] The user to notify
    # @param activity_type [Symbol] The type of suspicious activity
    # @param details [Hash] Additional details about the activity
    # @return [Notification] The created notification
    def self.suspicious_activity(user, activity_type, details = {})
      title = case activity_type
      when :login_attempt
                "Suspicious Login Attempt"
      when :unusual_location
                "Login from New Location"
      when :unusual_device
                "Login from New Device"
      when :multiple_failed_attempts
                "Multiple Failed Login Attempts"
      else
                "Suspicious Account Activity"
      end

      message = case activity_type
      when :login_attempt
                  location = details[:location].presence || "an unknown location"
                  "Someone attempted to log in to your account from #{location}."
      when :unusual_location
                  location = details[:location].presence || "an unknown location"
                  "Your account was accessed from #{location}, which is different from your usual locations."
      when :unusual_device
                  device = details[:device_type].presence || "an unknown device"
                  "Your account was accessed from a new #{device}."
      when :multiple_failed_attempts
                  attempts = details[:attempts].presence || "Multiple"
                  "#{attempts} failed login attempts have been detected on your account."
      else
                  "Unusual activity has been detected on your account."
      end

      # Determine severity based on type
      severity = case activity_type
      when :multiple_failed_attempts
                   :critical
      else
                   :warning
      end

      # Create notification
      NotificationService.notify(
        user: user,
        title: title,
        message: message,
        severity: severity,
        category: :security,
        action_url: security_settings_path,
        action_text: "Review Security",
        metadata: details.merge(activity_type: activity_type)
      )
    end

    # Send notification for PIN setup reminder
    # @param user [User] The user to notify
    # @return [Notification] The created notification
    def self.pin_setup_reminder(user)
      # Skip if user already has PIN
      return nil if user.pin_digest.present?

      # Create notification
      NotificationService.notify(
        user: user,
        title: "Secure Your Account",
        message: "Set up a transaction PIN to protect your funds with an additional layer of security.",
        severity: :info,
        category: :security,
        action_url: security_settings_path,
        action_text: "Set Up PIN",
        metadata: {
          reminder_type: :pin_setup
        }
      )
    end

    # Send notification for high-risk transaction
    # @param transaction [Transaction] The high-risk transaction
    # @param risk_score [Integer] The transaction risk score
    # @return [Notification] The created notification
    def self.high_risk_transaction(transaction, risk_score)
      user = transaction.source_wallet&.user || transaction.destination_wallet&.user

      return nil if user.nil?

      # Format amount and type
      amount_text = "#{transaction.formatted_amount} via #{transaction.payment_method.titleize}"

      # Create notification
      NotificationService.notify(
        user: user,
        title: "High Risk Transaction",
        message: "A #{transaction.transaction_type.titleize} for #{amount_text} was flagged as high risk (#{risk_score}/100).",
        severity: :warning,
        category: :security,
        action_url: wallet_transaction_path(transaction),
        action_text: "Review Transaction",
        metadata: {
          transaction_id: transaction.id,
          transaction_type: transaction.transaction_type,
          amount: transaction.amount,
          formatted_amount: transaction.formatted_amount,
          risk_score: risk_score
        }
      )
    end

    # Send notification for security settings change
    # @param user [User] The user to notify
    # @param setting_type [Symbol] The type of setting changed
    # @return [Notification] The created notification
    def self.security_setting_changed(user, setting_type)
      # Format message based on setting type
      message = case setting_type
      when :pin_created
                  "A transaction PIN has been set up for your account."
      when :pin_changed
                  "Your transaction PIN has been updated."
      when :pin_removed
                  "Your transaction PIN has been removed from your account."
      when :password_changed
                  "Your account password has been changed."
      when :email_changed
                  "Your account email address has been updated."
      when :phone_changed
                  "Your account phone number has been updated."
      else
                  "Your security settings have been updated."
      end

      # Determine severity
      severity = case setting_type
      when :pin_removed, :email_changed
                   :warning
      else
                   :info
      end

      # Create notification
      NotificationService.notify(
        user: user,
        title: "Security Setting Updated",
        message: message,
        severity: severity,
        category: :security,
        action_url: security_settings_path,
        action_text: "View Settings",
        metadata: {
          setting_type: setting_type
        }
      )
    end

    # Send notification for account lockout
    # @param user [User] The user to notify
    # @param reason [Symbol] The reason for lockout
    # @return [Notification] The created notification
    def self.account_locked(user, reason = nil)
      # Format message based on reason
      message = case reason
      when :suspicious_activity
                  "Your account has been locked due to suspicious activity."
      when :multiple_failed_attempts
                  "Your account has been locked due to multiple failed login attempts."
      when :user_initiated
                  "Your account has been locked at your request."
      else
                  "Your account has been locked for security reasons."
      end

      message += " Please contact support to unlock your account."

      # Create notification
      NotificationService.notify(
        user: user,
        title: "Account Locked",
        message: message,
        severity: :critical,
        category: :security,
        action_text: "Contact Support",
        metadata: {
          reason: reason
        }
      )
    end
  end
end
