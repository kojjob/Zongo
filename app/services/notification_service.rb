class NotificationService
  # Send a notification to a user
  # @param user [User] The user to notify
  # @param title [String] Notification title
  # @param message [String] Notification message
  # @param options [Hash] Additional options
  # @option options [Symbol] :severity (:info) Notification severity (:info, :warning, :critical)
  # @option options [Symbol] :category (:general) Notification category (:general, :security, :transaction, :account, :system)
  # @option options [String] :action_url (nil) URL for action button
  # @option options [String] :action_text (nil) Text for action button
  # @option options [Hash] :metadata ({}) Additional data related to the notification
  # @option options [String] :image_url (nil) URL for notification image
  # @option options [String] :icon (nil) Icon name for notification
  # @option options [Array<Symbol>] :channels ([:in_app]) Notification channels to use (:in_app, :email, :sms, :push)
  # @option options [Boolean] :broadcast (true) Whether to broadcast the notification via ActionCable
  # @return [Notification] The created notification
  def self.notify(user, title, message, options = {})
    return nil unless user
    
    # Extract options
    severity = options[:severity] || :info
    category = options[:category] || :general
    action_url = options[:action_url]
    action_text = options[:action_text]
    metadata = options[:metadata] || {}
    image_url = options[:image_url]
    icon = options[:icon]
    channels = options[:channels] || [:in_app]
    broadcast = options.key?(:broadcast) ? options[:broadcast] : true
    
    # Create notification
    notification = user.notifications.create!(
      title: title,
      message: message,
      severity: severity,
      category: category,
      action_url: action_url,
      action_text: action_text,
      metadata: metadata,
      image_url: image_url,
      icon: icon
    )
    
    # Deliver through specified channels
    notification.deliver_through(channels) if broadcast
    
    notification
  end
  
  # Send a notification to multiple users
  # @param users [Array<User>] Users to notify
  # @param title [String] Notification title
  # @param message [String] Notification message
  # @param options [Hash] Additional options (see #notify)
  # @return [Array<Notification>] Created notifications
  def self.notify_many(users, title, message, options = {})
    return [] if users.blank?
    
    # Extract channels option
    channels = options[:channels] || [:in_app]
    
    if users.size > 10
      # For large numbers of users, use background job
      user_ids = users.map(&:id)
      
      # Create notification params
      notification_params = {
        title: title,
        message: message,
        severity: options[:severity] || :info,
        category: options[:category] || :general,
        action_url: options[:action_url],
        action_text: options[:action_text],
        metadata: options[:metadata] || {},
        image_url: options[:image_url],
        icon: options[:icon]
      }
      
      # Queue job
      BulkNotificationJob.perform_later(user_ids, notification_params, channels)
      
      []
    else
      # For small numbers of users, create notifications immediately
      users.map do |user|
        notify(user, title, message, options)
      end
    end
  end
  
  # Send a security notification
  # @param user [User] The user to notify
  # @param title [String] Notification title
  # @param message [String] Notification message
  # @param options [Hash] Additional options (see #notify)
  # @return [Notification] The created notification
  def self.security_notification(user, title, message, options = {})
    options[:category] = :security
    options[:severity] = options[:severity] || :warning
    options[:channels] = options[:channels] || [:in_app, :email]
    
    notify(user, title, message, options)
  end
  
  # Send a transaction notification
  # @param user [User] The user to notify
  # @param title [String] Notification title
  # @param message [String] Notification message
  # @param options [Hash] Additional options (see #notify)
  # @return [Notification] The created notification
  def self.transaction_notification(user, title, message, options = {})
    options[:category] = :transaction
    options[:channels] = options[:channels] || [:in_app]
    
    notify(user, title, message, options)
  end
  
  # Send an account notification
  # @param user [User] The user to notify
  # @param title [String] Notification title
  # @param message [String] Notification message
  # @param options [Hash] Additional options (see #notify)
  # @return [Notification] The created notification
  def self.account_notification(user, title, message, options = {})
    options[:category] = :account
    
    notify(user, title, message, options)
  end
  
  # Send a system notification
  # @param user [User] The user to notify
  # @param title [String] Notification title
  # @param message [String] Notification message
  # @param options [Hash] Additional options (see #notify)
  # @return [Notification] The created notification
  def self.system_notification(user, title, message, options = {})
    options[:category] = :system
    
    notify(user, title, message, options)
  end
  
  # Send a notification for a new login
  # @param user [User] The user to notify
  # @param ip_address [String] IP address of the login
  # @param user_agent [String] User agent of the login
  # @param location [String] Location of the login
  # @param options [Hash] Additional options (see #notify)
  # @return [Notification] The created notification
  def self.new_login_notification(user, ip_address, user_agent, location = nil, options = {})
    title = "New Login Detected"
    message = "Your account was accessed from a new location or device."
    
    metadata = {
      ip_address: ip_address,
      user_agent: user_agent,
      location: location,
      timestamp: Time.current
    }
    
    options[:category] = :security
    options[:severity] = :info
    options[:metadata] = metadata
    options[:action_url] = "/account/security"
    options[:action_text] = "Review Activity"
    options[:channels] = options[:channels] || [:in_app, :email]
    
    notify(user, title, message, options)
  end
  
  # Send a notification for a suspicious login
  # @param user [User] The user to notify
  # @param ip_address [String] IP address of the login
  # @param user_agent [String] User agent of the login
  # @param location [String] Location of the login
  # @param reason [String] Reason for suspicion
  # @param options [Hash] Additional options (see #notify)
  # @return [Notification] The created notification
  def self.suspicious_login_notification(user, ip_address, user_agent, location = nil, reason = nil, options = {})
    title = "Suspicious Login Detected"
    message = "We detected a suspicious login attempt to your account."
    message += " Reason: #{reason}" if reason.present?
    
    metadata = {
      ip_address: ip_address,
      user_agent: user_agent,
      location: location,
      reason: reason,
      timestamp: Time.current
    }
    
    options[:category] = :security
    options[:severity] = :critical
    options[:metadata] = metadata
    options[:action_url] = "/account/security"
    options[:action_text] = "Secure Account"
    options[:channels] = options[:channels] || [:in_app, :email, :sms]
    
    notify(user, title, message, options)
  end
  
  # Send a notification for a password change
  # @param user [User] The user to notify
  # @param ip_address [String] IP address of the change
  # @param options [Hash] Additional options (see #notify)
  # @return [Notification] The created notification
  def self.password_changed_notification(user, ip_address, options = {})
    title = "Password Changed"
    message = "Your account password was recently changed."
    
    metadata = {
      ip_address: ip_address,
      timestamp: Time.current
    }
    
    options[:category] = :security
    options[:severity] = :info
    options[:metadata] = metadata
    options[:action_url] = "/account/security"
    options[:action_text] = "Review Activity"
    options[:channels] = options[:channels] || [:in_app, :email]
    
    notify(user, title, message, options)
  end
  
  # Send a notification for a successful transaction
  # @param user [User] The user to notify
  # @param transaction [Transaction] The transaction
  # @param options [Hash] Additional options (see #notify)
  # @return [Notification] The created notification
  def self.transaction_completed_notification(user, transaction, options = {})
    transaction_type = transaction.transaction_type.to_s.humanize
    amount = transaction.amount
    currency = transaction.currency || "GHS"
    
    title = "#{transaction_type} Completed"
    message = "Your #{transaction_type.downcase} of #{currency} #{amount} has been completed successfully."
    
    metadata = {
      transaction_id: transaction.id,
      transaction_type: transaction.transaction_type,
      amount: amount,
      currency: currency,
      timestamp: transaction.created_at
    }
    
    options[:category] = :transaction
    options[:severity] = :info
    options[:metadata] = metadata
    options[:action_url] = "/transactions/#{transaction.id}"
    options[:action_text] = "View Details"
    options[:channels] = options[:channels] || [:in_app]
    
    notify(user, title, message, options)
  end
  
  # Send a notification for a failed transaction
  # @param user [User] The user to notify
  # @param transaction [Transaction] The transaction
  # @param reason [String] Reason for failure
  # @param options [Hash] Additional options (see #notify)
  # @return [Notification] The created notification
  def self.transaction_failed_notification(user, transaction, reason = nil, options = {})
    transaction_type = transaction.transaction_type.to_s.humanize
    amount = transaction.amount
    currency = transaction.currency || "GHS"
    
    title = "#{transaction_type} Failed"
    message = "Your #{transaction_type.downcase} of #{currency} #{amount} has failed."
    message += " Reason: #{reason}" if reason.present?
    
    metadata = {
      transaction_id: transaction.id,
      transaction_type: transaction.transaction_type,
      amount: amount,
      currency: currency,
      reason: reason,
      timestamp: transaction.created_at
    }
    
    options[:category] = :transaction
    options[:severity] = :warning
    options[:metadata] = metadata
    options[:action_url] = "/transactions/#{transaction.id}"
    options[:action_text] = "View Details"
    options[:channels] = options[:channels] || [:in_app]
    
    notify(user, title, message, options)
  end
  
  # Send a notification for a low balance
  # @param user [User] The user to notify
  # @param wallet [Wallet] The wallet
  # @param options [Hash] Additional options (see #notify)
  # @return [Notification] The created notification
  def self.low_balance_notification(user, wallet, options = {})
    balance = wallet.balance
    currency = wallet.currency || "GHS"
    threshold = wallet.low_balance_threshold || 50
    
    title = "Low Balance Alert"
    message = "Your wallet balance is below #{currency} #{threshold}. Current balance: #{currency} #{balance}."
    
    metadata = {
      wallet_id: wallet.id,
      balance: balance,
      currency: currency,
      threshold: threshold,
      timestamp: Time.current
    }
    
    options[:category] = :account
    options[:severity] = :warning
    options[:metadata] = metadata
    options[:action_url] = "/wallet"
    options[:action_text] = "Add Funds"
    options[:channels] = options[:channels] || [:in_app]
    
    notify(user, title, message, options)
  end
  
  # Send a notification for a new message
  # @param user [User] The user to notify
  # @param sender [User] The sender of the message
  # @param message_content [String] The message content
  # @param conversation_id [Integer] The conversation ID
  # @param options [Hash] Additional options (see #notify)
  # @return [Notification] The created notification
  def self.new_message_notification(user, sender, message_content, conversation_id, options = {})
    title = "New Message from #{sender.display_name}"
    
    # Truncate message content if too long
    truncated_content = message_content.truncate(100)
    
    metadata = {
      sender_id: sender.id,
      sender_name: sender.display_name,
      conversation_id: conversation_id,
      timestamp: Time.current
    }
    
    options[:category] = :general
    options[:severity] = :info
    options[:metadata] = metadata
    options[:action_url] = "/conversations/#{conversation_id}"
    options[:action_text] = "View Message"
    options[:channels] = options[:channels] || [:in_app]
    
    notify(user, title, truncated_content, options)
  end
end
