class NotificationMailer < ApplicationMailer
  # Default settings
  default from: 'notifications@example.com'
  
  # Send a notification email
  # @param delivery [NotificationDelivery] The notification delivery record
  def send_notification(delivery)
    @delivery = delivery
    @notification = delivery.notification
    @user = delivery.user
    @channel = delivery.notification_channel
    
    # Set email subject based on notification severity
    subject_prefix = case @notification.severity
                     when 'critical' then '[URGENT] '
                     when 'warning' then '[IMPORTANT] '
                     else ''
                     end
    
    mail(
      to: @channel.identifier,
      subject: "#{subject_prefix}#{@notification.title}"
    )
  end
  
  # Send a verification email
  # @param channel [NotificationChannel] The notification channel to verify
  def verify_email(channel)
    @channel = channel
    @user = channel.user
    @verification_token = channel.verification_token
    @verification_url = verification_url(@verification_token)
    
    mail(
      to: channel.identifier,
      subject: 'Verify your email address'
    )
  end
  
  # Send a security alert
  # @param user [User] The user to notify
  # @param title [String] Alert title
  # @param message [String] Alert message
  # @param action_url [String] URL for action button
  # @param metadata [Hash] Additional data
  def security_alert(user, title, message, action_url = nil, metadata = {})
    @user = user
    @title = title
    @message = message
    @action_url = action_url
    @metadata = metadata
    @ip_address = metadata[:ip_address]
    @location = metadata[:location]
    @device = metadata[:device]
    @browser = metadata[:browser]
    @timestamp = metadata[:timestamp] || Time.current
    
    mail(
      to: user.email,
      subject: "[SECURITY ALERT] #{title}"
    )
  end
  
  # Send a transaction notification
  # @param user [User] The user to notify
  # @param transaction [Transaction] The transaction
  def transaction_notification(user, transaction)
    @user = user
    @transaction = transaction
    @transaction_type = transaction.transaction_type
    @amount = transaction.amount
    @currency = transaction.currency || 'GHS'
    @status = transaction.status
    @timestamp = transaction.created_at
    
    subject = case @transaction_type
              when 'deposit' then "Deposit of #{@currency} #{@amount} #{@status}"
              when 'withdrawal' then "Withdrawal of #{@currency} #{@amount} #{@status}"
              when 'transfer' then "Transfer of #{@currency} #{@amount} #{@status}"
              else "Transaction of #{@currency} #{@amount} #{@status}"
              end
    
    mail(
      to: user.email,
      subject: subject
    )
  end
  
  private
  
  # Generate verification URL
  # @param token [String] Verification token
  # @return [String] Verification URL
  def verification_url(token)
    verify_notification_channel_url(token: token)
  end
end
