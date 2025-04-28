# Notification System Seeds
# This file contains seed data for testing the notification system

puts "Creating notification preferences for users..."

# Create notification preferences for all users
User.find_each do |user|
  # Skip if user already has notification preferences
  next if user.notification_preference.present?

  # Create notification preference with default settings
  preference = user.create_notification_preference(
    email_enabled: true,
    sms_enabled: true,
    push_enabled: true,
    in_app_enabled: true,
    email_preferences: {
      'general' => true,
      'security' => true,
      'transaction' => true,
      'account' => true,
      'system' => true
    },
    sms_preferences: {
      'security' => true,
      'transaction' => true
    },
    push_preferences: {
      'general' => true,
      'security' => true,
      'transaction' => true,
      'account' => true,
      'system' => false
    },
    in_app_preferences: {
      'general' => true,
      'security' => true,
      'transaction' => true,
      'account' => true,
      'system' => true
    }
  )

  puts "  Created notification preferences for #{user.email}"
end

puts "Creating notification channels for users..."

# Create notification channels for some users
User.limit(10).each do |user|
  # Create email channel (verified)
  email_channel = user.notification_channels.create!(
    channel_type: 'email',
    identifier: user.email,
    verified: true,
    enabled: true,
    verification_token: SecureRandom.hex(3).upcase,
    verified_at: Time.current
  )

  # Create SMS channel (some verified, some not)
  phone_number = "+233#{rand(200000000..299999999)}"
  verified = [true, false].sample

  sms_channel = user.notification_channels.create!(
    channel_type: 'sms',
    identifier: phone_number,
    verified: verified,
    enabled: verified,
    verification_token: SecureRandom.hex(3).upcase,
    verified_at: verified ? Time.current : nil
  )

  # Create push channel for some users
  if rand < 0.7
    device_token = SecureRandom.hex(32)
    user.notification_channels.create!(
      channel_type: 'push',
      identifier: "device_#{device_token}",
      verified: true,
      enabled: true,
      verification_token: nil,
      verified_at: Time.current
    )
  end

  puts "  Created notification channels for #{user.email}"
end

puts "Creating sample notifications for users..."

# Sample notification data
notification_data = [
  {
    category: 'general',
    severity: 'info',
    title: 'Welcome to Zongo',
    message: 'Thank you for joining Zongo. We\'re excited to have you on board!',
    action_url: '/dashboard',
    action_text: 'Go to Dashboard',
    icon: 'information-circle',
    metadata: { welcome: true, first_login: true }
  },
  {
    category: 'security',
    severity: 'critical',
    title: 'New Login Detected',
    message: 'Your account was accessed from a new device in Accra, Ghana.',
    action_url: '/account/security',
    action_text: 'Review Activity',
    icon: 'shield-exclamation',
    metadata: { ip_address: '102.176.0.123', location: 'Accra, Ghana', device: 'iPhone', browser: 'Safari' }
  },
  {
    category: 'transaction',
    severity: 'info',
    title: 'Payment Successful',
    message: 'Your payment of GHS 250.00 to MTN Mobile Money was successful.',
    action_url: '/transactions/123456',
    action_text: 'View Receipt',
    icon: 'currency-dollar',
    metadata: { transaction_id: '123456', amount: 250.00, recipient: 'MTN Mobile Money', status: 'completed' }
  },
  {
    category: 'transaction',
    severity: 'warning',
    title: 'Payment Failed',
    message: 'Your payment of GHS 100.00 to Vodafone Cash failed due to insufficient funds.',
    action_url: '/wallet',
    action_text: 'Add Funds',
    icon: 'exclamation-circle',
    metadata: { transaction_id: '123457', amount: 100.00, recipient: 'Vodafone Cash', status: 'failed', reason: 'insufficient_funds' }
  },
  {
    category: 'account',
    severity: 'info',
    title: 'Profile Updated',
    message: 'Your profile information has been successfully updated.',
    action_url: '/profile',
    action_text: 'View Profile',
    icon: 'user-circle',
    metadata: { updated_fields: ['phone', 'address'] }
  },
  {
    category: 'account',
    severity: 'warning',
    title: 'Low Balance Alert',
    message: 'Your wallet balance is below GHS 50.00. Current balance: GHS 35.75.',
    action_url: '/wallet',
    action_text: 'Add Funds',
    icon: 'cash',
    metadata: { balance: 35.75, threshold: 50.00, currency: 'GHS' }
  },
  {
    category: 'system',
    severity: 'info',
    title: 'System Maintenance',
    message: 'Zongo will be undergoing maintenance on Sunday, July 10th from 2:00 AM to 4:00 AM GMT.',
    action_url: '/support/announcements',
    action_text: 'Learn More',
    icon: 'cog',
    metadata: { maintenance_id: '789', start_time: '2023-07-10T02:00:00Z', end_time: '2023-07-10T04:00:00Z' }
  },
  {
    category: 'security',
    severity: 'warning',
    title: 'Password Changed',
    message: 'Your account password was recently changed. If you didn\'t make this change, please contact support immediately.',
    action_url: '/account/security',
    action_text: 'Review Activity',
    icon: 'lock-closed',
    metadata: { timestamp: Time.current - 1.hour, ip_address: '102.176.0.123' }
  },
  {
    category: 'general',
    severity: 'info',
    title: 'New Feature Available',
    message: 'You can now send money to multiple recipients at once with our new Bulk Transfer feature.',
    action_url: '/wallet/transfer',
    action_text: 'Try It Now',
    icon: 'gift',
    metadata: { feature_id: 'bulk_transfer', release_date: Date.today - 2.days }
  },
  {
    category: 'transaction',
    severity: 'info',
    title: 'Money Received',
    message: 'You received GHS 500.00 from John Doe.',
    action_url: '/transactions/123458',
    action_text: 'View Details',
    icon: 'arrow-down-circle',
    metadata: { transaction_id: '123458', amount: 500.00, sender: 'John Doe', status: 'completed' }
  }
]

# Create notifications for users
User.limit(20).each do |user|
  # Create 3-7 random notifications for each user
  notification_count = rand(3..7)

  notification_count.times do
    # Select a random notification template
    notification_template = notification_data.sample

    # Create the notification
    notification = user.notifications.create!(
      title: notification_template[:title],
      message: notification_template[:message],
      category: notification_template[:category],
      severity: notification_template[:severity],
      action_url: notification_template[:action_url],
      action_text: notification_template[:action_text],
      icon: notification_template[:icon],
      metadata: notification_template[:metadata],
      read: [true, false].sample,
      read_at: [true, false].sample ? Time.current - rand(1..24).hours : nil,
      created_at: Time.current - rand(1..30).days
    )
  end

  # Create one unread notification for each user
  unread_template = notification_data.sample
  user.notifications.create!(
    title: unread_template[:title],
    message: unread_template[:message],
    category: unread_template[:category],
    severity: unread_template[:severity],
    action_url: unread_template[:action_url],
    action_text: unread_template[:action_text],
    icon: unread_template[:icon],
    metadata: unread_template[:metadata],
    read: false,
    read_at: nil,
    created_at: Time.current - rand(1..24).hours
  )

  puts "  Created notifications for #{user.email}"
end

puts "Creating notification deliveries..."

# Create some notification deliveries
Notification.limit(30).each do |notification|
  user = notification.user

  # Create email delivery
  if user.notification_channels.where(channel_type: 'email').exists? && rand < 0.8
    email_channel = user.notification_channels.where(channel_type: 'email').first

    status = ['pending', 'delivered', 'failed'].sample
    delivery = NotificationDelivery.create!(
      notification: notification,
      user: user,
      notification_channel: email_channel,
      channel_type: 'email',
      status: status,
      delivered_at: status == 'delivered' ? Time.current - rand(1..60).minutes : nil,
      attempts: rand(1..3),
      error_message: status == 'failed' ? 'Failed to deliver email' : nil
    )
  end

  # Create SMS delivery
  if user.notification_channels.where(channel_type: 'sms').exists? && rand < 0.6
    sms_channel = user.notification_channels.where(channel_type: 'sms').first

    status = ['pending', 'delivered', 'failed'].sample
    delivery = NotificationDelivery.create!(
      notification: notification,
      user: user,
      notification_channel: sms_channel,
      channel_type: 'sms',
      status: status,
      delivered_at: status == 'delivered' ? Time.current - rand(1..60).minutes : nil,
      attempts: rand(1..3),
      error_message: status == 'failed' ? 'Failed to deliver SMS' : nil
    )
  end

  # Create push delivery
  if user.notification_channels.where(channel_type: 'push').exists? && rand < 0.7
    push_channel = user.notification_channels.where(channel_type: 'push').first

    status = ['pending', 'delivered', 'failed'].sample
    delivery = NotificationDelivery.create!(
      notification: notification,
      user: user,
      notification_channel: push_channel,
      channel_type: 'push',
      status: status,
      delivered_at: status == 'delivered' ? Time.current - rand(1..60).minutes : nil,
      attempts: rand(1..3),
      error_message: status == 'failed' ? 'Failed to deliver push notification' : nil
    )
  end
end

puts "Notification system seed data created successfully!"
