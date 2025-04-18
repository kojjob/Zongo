class SecurityAlertService
  # Constants for alert types
  SEVERITY_LEVELS = {
    low: 0,      # Informational, no immediate action needed
    medium: 1,   # Requires attention but not urgent
    high: 2,     # Requires prompt attention
    critical: 3  # Requires immediate attention
  }

  ALERT_CATEGORIES = {
    authentication: 0,      # Login attempts, 2FA, password changes
    transaction: 1,         # Money transfers, payments, deposits
    account_change: 2,      # Profile, settings updates
    device: 3,              # New device, location, IP
    pattern_detection: 4,   # ML-detected anomalies
    external_threat: 5      # Third-party reported threats
  }

  # Initialize with configuration options
  # @param real_time [Boolean] Enable real-time notifications
  # @param ml_enhanced [Boolean] Use machine learning for pattern detection
  # @param third_party_integrations [Array] List of third-party services to use
  def initialize(real_time: true, ml_enhanced: true, third_party_integrations: [])
    @real_time = real_time
    @ml_enhanced = ml_enhanced
    @third_party_integrations = third_party_integrations
    @fraud_score_threshold = Rails.configuration.x.security.fraud_score_threshold || 70
  end

  # Process a security event and determine if alerts should be triggered
  # @param event_type [Symbol] Type of security event
  # @param user [User] The user associated with the event
  # @param context [Hash] Contextual information about the event
  # @param immediate [Boolean] Force immediate notification regardless of settings
  # @return [Hash] Result of alert processing including alert IDs and actions taken
  def process_event(event_type, user, context = {}, immediate: false)
    return { success: false, error: "No user provided" } unless user

    # Initialize result hash
    result = {
      success: false,
      alerts: [],
      actions: [],
      risk_score: nil
    }

    # Generate alert data
    alert_data = build_alert_data(event_type, user, context)

    # Calculate risk score using ML if enabled
    risk_score = calculate_risk_score(event_type, user, context)
    result[:risk_score] = risk_score

    # Determine severity based on risk score
    severity = determine_severity(risk_score, event_type)

    # Determine category based on event type
    category = map_to_category(event_type)

    # Log the security event regardless of severity
    security_log = log_security_event(user, event_type, severity, alert_data, context)
    result[:security_log_id] = security_log.id

    # Check for threat intelligence from third-party services
    threat_intel = check_threat_intelligence(context) if @third_party_integrations.any?

    if threat_intel && threat_intel[:threat_detected]
      # Increase severity if external threat intelligence found a match
      severity = [ severity, SEVERITY_LEVELS[:high] ].max
      alert_data[:threat_intel] = threat_intel
    end

    # Determine if we should send a notification
    should_notify = determine_if_notification_needed(severity, user, context, immediate)

    if should_notify
      # Create alert notification
      notification = create_notification(user, event_type, severity, category, alert_data)
      result[:notification_id] = notification.id if notification
      result[:alerts] << { type: "notification", id: notification.id } if notification

      # For high severity or critical alerts, take additional actions
      if severity >= SEVERITY_LEVELS[:high]
        actions = take_security_actions(user, event_type, severity, context)
        result[:actions] = actions
      end
    end

    # For very high risk scores, alert security team
    if risk_score > @fraud_score_threshold
      alert_security_team(user, event_type, risk_score, alert_data, context)
      result[:alerts] << { type: "security_team_alert", risk_score: risk_score }
    end

    result[:success] = true
    result
  end

  # Create and send appropriate notifications based on the security event
  # @param user [User] User to notify
  # @param event_type [Symbol] Type of security event
  # @param severity [Integer] Severity level
  # @param category [Integer] Alert category
  # @param alert_data [Hash] Alert data and context
  # @return [Notification] The created notification
  def create_notification(user, event_type, severity, category, alert_data)
    # Map severity to notification severity
    notification_severity = case severity
    when SEVERITY_LEVELS[:critical]
                              :critical
    when SEVERITY_LEVELS[:high]
                              :warning
    when SEVERITY_LEVELS[:medium]
                              :warning
    else
                              :info
    end

    # Map category to notification category
    notification_category = :security

    # Build appropriate title and message based on event type
    title, message, metadata = build_notification_content(event_type, alert_data)

    # Determine appropriate action URL
    action_url = determine_action_url(event_type)

    # Create notification using existing NotificationService
    Notifications::NotificationService.notify(
      user: user,
      title: title,
      message: message,
      severity: notification_severity,
      category: notification_category,
      action_url: action_url,
      action_text: nil, # Use default
      metadata: metadata.merge(alert_data)
    )
  end

  # Take automated security actions based on severity and event type
  # @param user [User] Affected user
  # @param event_type [Symbol] Type of security event
  # @param severity [Integer] Severity level
  # @param context [Hash] Event context
  # @return [Array<Hash>] List of actions taken
  def take_security_actions(user, event_type, severity, context)
    actions = []

    case event_type
    when :suspicious_login, :brute_force_attempt
      if severity >= SEVERITY_LEVELS[:critical]
        # Lock account for severe security issues
        user.update(locked_at: Time.current, locked_reason: "Suspicious activity detected")
        SecurityLog.log_event(user, :account_locked, severity: :critical,
          details: { reason: "Automated response to critical security alert" })
        actions << { action: :account_locked, user_id: user.id }
      elsif severity >= SEVERITY_LEVELS[:high]
        # Require additional verification on next login
        user.update(security_verification_required: true)
        actions << { action: :verification_required, user_id: user.id }
      end

    when :unusual_transaction, :potential_fraud
      if severity >= SEVERITY_LEVELS[:high]
        # If this is related to a transaction, find and block it
        if context[:transaction_id]
          transaction = Transaction.find_by(id: context[:transaction_id])
          if transaction && !transaction.completed?
            transaction.update(status: :blocked,
              metadata: transaction.metadata.merge(
                block_reason: "Security alert: #{context[:reason]}"
              )
            )
            actions << { action: :transaction_blocked, transaction_id: transaction.id }

            # Also notify using the existing service
            Notifications::SecurityNotificationService.blocked_transaction(transaction)
          end
        end

        # Temporarily reduce transaction limits
        if user.wallet && severity >= SEVERITY_LEVELS[:critical]
          original_limit = user.wallet.daily_limit
          reduced_limit = original_limit * 0.5 # Reduce to 50%

          user.wallet.update(
            daily_limit: reduced_limit,
            limit_reduction_reason: "Security alert",
            original_limit: original_limit,
            limit_reset_at: 24.hours.from_now
          )
          actions << { action: :reduced_limits, user_id: user.id, original_limit: original_limit, new_limit: reduced_limit }
        end
      end

    when :new_device, :new_location
      if severity >= SEVERITY_LEVELS[:medium]
        # Require additional verification for new devices/locations
        user.update(device_verification_required: true)
        actions << { action: :device_verification_required, user_id: user.id }
      end
    end

    actions
  end

  # Alert security team for high-risk events
  # @param user [User] Affected user
  # @param event_type [Symbol] Type of security event
  # @param risk_score [Integer] Risk score (0-100)
  # @param alert_data [Hash] Alert data
  # @param context [Hash] Event context
  def alert_security_team(user, event_type, risk_score, alert_data, context)
    # Build alert data for security team
    security_alert = {
      user_id: user.id,
      user_email: user.email,
      user_phone: user.phone,
      event_type: event_type,
      risk_score: risk_score,
      timestamp: Time.current,
      alert_data: alert_data,
      context: context
    }

    # In a real implementation, you would send this to your security monitoring platform
    # Examples include PagerDuty, OpsGenie, or a custom security dashboard

    # Send to security Slack channel
    if defined?(SlackNotifier)
      begin
        SlackNotifier.security_alert(security_alert)
      rescue => e
        Rails.logger.error("Failed to send security alert to Slack: #{e.message}")
      end
    end

    # Log to security monitoring system
    if defined?(SecurityMonitoring)
      begin
        SecurityMonitoring.create_alert(security_alert)
      rescue => e
        Rails.logger.error("Failed to create security monitoring alert: #{e.message}")
      end
    end

    # For critical alerts, consider paging on-call security personnel
    if risk_score > 85 && defined?(PagerDuty)
      begin
        PagerDuty.trigger_incident(
          title: "Critical security alert for user #{user.id}",
          details: security_alert,
          urgency: "high"
        )
      rescue => e
        Rails.logger.error("Failed to trigger PagerDuty incident: #{e.message}")
      end
    end

    # Always log high-risk events to a dedicated security log
    Rails.logger.warn("HIGH RISK SECURITY ALERT: #{security_alert.to_json}")
  end

  # Check third-party threat intelligence for additional context
  # @param context [Hash] Event context including IP, device info, etc.
  # @return [Hash, nil] Threat intelligence data if available
  def check_threat_intelligence(context)
    return nil if @third_party_integrations.empty?

    threat_data = { threat_detected: false }

    # Check IP reputation if IP is provided
    if context[:ip_address].present? && @third_party_integrations.include?(:ip_intelligence)
      begin
        # This would be replaced with an actual third-party API call
        # Example: ip_data = IPIntelligenceService.check_ip(context[:ip_address])
        ip_data = mock_ip_intelligence_check(context[:ip_address])

        if ip_data[:suspicious]
          threat_data[:threat_detected] = true
          threat_data[:ip_data] = ip_data
        end
      rescue => e
        Rails.logger.error("Failed to check IP reputation: #{e.message}")
      end
    end

    # Check device fingerprint against known fraudulent devices
    if context[:device_fingerprint].present? && @third_party_integrations.include?(:device_intelligence)
      begin
        # This would be replaced with an actual third-party API call
        # Example: device_data = DeviceFraudService.check_device(context[:device_fingerprint])
        device_data = mock_device_intelligence_check(context[:device_fingerprint])

        if device_data[:suspicious]
          threat_data[:threat_detected] = true
          threat_data[:device_data] = device_data
        end
      rescue => e
        Rails.logger.error("Failed to check device reputation: #{e.message}")
      end
    end

    threat_data
  end

  # Calculate risk score for a security event using ML if enabled
  # @param event_type [Symbol] Type of security event
  # @param user [User] The user associated with the event
  # @param context [Hash] Contextual information about the event
  # @return [Integer] Risk score (0-100)
  def calculate_risk_score(event_type, user, context)
    if @ml_enhanced && defined?(RiskScoringService)
      begin
        # This would be replaced with a real ML-based risk scoring service
        return RiskScoringService.calculate_risk(user, event_type, context)
      rescue => e
        Rails.logger.error("ML risk scoring failed: #{e.message}")
        # Fall back to rules-based calculation
      end
    end

    # Simple rules-based risk scoring as fallback
    score = 0

    # Base score by event type
    score += case event_type
    when :successful_login then 5
    when :failed_login then 20
    when :multiple_failed_logins then 50
    when :password_changed then 30
    when :email_changed then 40
    when :phone_changed then 40
    when :unusual_transaction then 40
    when :large_transaction then 30
    when :new_device then 35
    when :new_location then 30
    when :unusual_time then 25
    when :unusual_pattern then 45
    when :potential_fraud then 65
    else 10
    end

    # Adjust by user account age
    account_age_days = ((Time.current - user.created_at) / 1.day).to_i
    if account_age_days < 7
      score += 30
    elsif account_age_days < 30
      score += 15
    elsif account_age_days > 365
      score -= 10
    end

    # Adjust by user transaction history
    if defined?(Transaction)
      transaction_count = Transaction.where("source_wallet_id IN (?) OR destination_wallet_id IN (?)",
                                          user.wallet.id, user.wallet.id).count
      if transaction_count < 5
        score += 20
      elsif transaction_count > 50
        score -= 10
      end
    end

    # Adjust based on recent suspicious activity
    if SecurityLog.recent_suspicious_activity?(user.id)
      score += 25
    end

    # Adjust based on device/location
    if context[:is_new_device] == true
      score += 20
    end

    if context[:is_new_location] == true
      score += 20
    end

    # Cap at 0-100 range
    [ 0, [ score, 100 ].min ].max
  end

  # Determine severity based on risk score and event type
  # @param risk_score [Integer] The calculated risk score
  # @param event_type [Symbol] Type of security event
  # @return [Integer] Severity level from SEVERITY_LEVELS
  def determine_severity(risk_score, event_type)
    # Critical events always get high severity regardless of score
    critical_events = [ :multiple_failed_logins, :potential_fraud, :account_takeover_attempt ]
    return SEVERITY_LEVELS[:critical] if critical_events.include?(event_type)

    # Otherwise determine by risk score
    if risk_score >= 80
      SEVERITY_LEVELS[:critical]
    elsif risk_score >= 60
      SEVERITY_LEVELS[:high]
    elsif risk_score >= 40
      SEVERITY_LEVELS[:medium]
    else
      SEVERITY_LEVELS[:low]
    end
  end

  # Map event type to alert category
  # @param event_type [Symbol] Type of security event
  # @return [Integer] Category from ALERT_CATEGORIES
  def map_to_category(event_type)
    case event_type
    when :successful_login, :failed_login, :multiple_failed_logins,
         :password_changed, :pin_changed, :two_factor_enabled, :two_factor_disabled
      ALERT_CATEGORIES[:authentication]

    when :unusual_transaction, :large_transaction, :suspicious_transaction,
         :international_transaction, :potential_fraud, :transaction_blocked
      ALERT_CATEGORIES[:transaction]

    when :email_changed, :phone_changed, :profile_updated, :account_settings_changed
      ALERT_CATEGORIES[:account_change]

    when :new_device, :new_location, :unusual_time, :unusual_ip
      ALERT_CATEGORIES[:device]

    when :unusual_pattern, :velocity_detected, :behavior_anomaly
      ALERT_CATEGORIES[:pattern_detection]

    when :external_threat_detected, :blacklist_match
      ALERT_CATEGORIES[:external_threat]

    else
      # Default
      ALERT_CATEGORIES[:authentication]
    end
  end

  # Build notification content based on event type
  # @param event_type [Symbol] Type of security event
  # @param alert_data [Hash] Alert data and context
  # @return [Array<String, String, Hash>] Title, message, and metadata
  def build_notification_content(event_type, alert_data)
    location = alert_data[:location].presence || "an unknown location"
    time = alert_data[:time]&.strftime("%B %d at %H:%M") || "recently"
    device = alert_data[:device_type].presence || "an unknown device"

    case event_type
    when :successful_login
      title = "New Account Login"
      message = "Your account was accessed from #{location} on #{device} at #{time}."
      metadata = { event: "login", location: location, device: device }

    when :failed_login
      title = "Failed Login Attempt"
      message = "Someone attempted to log in to your account from #{location}."
      metadata = { event: "failed_login", location: location }

    when :multiple_failed_logins
      attempts = alert_data[:attempts] || "Multiple"
      title = "Multiple Failed Login Attempts"
      message = "#{attempts} failed login attempts detected on your account from #{location}."
      metadata = { event: "multiple_failed_logins", attempts: attempts, location: location }

    when :unusual_transaction
      amount = alert_data[:amount].presence || "An"
      title = "Unusual Transaction Detected"
      message = "#{amount} transaction was flagged as unusual. If this wasn't you, please contact support immediately."
      metadata = { event: "unusual_transaction", amount: amount }

    when :large_transaction
      amount = alert_data[:amount].presence || "A large"
      title = "Large Transaction Alert"
      message = "#{amount} transaction was initiated from your account. If this wasn't you, please contact support."
      metadata = { event: "large_transaction", amount: amount }

    when :new_device
      title = "New Device Logged In"
      message = "Your account was accessed from a new device (#{device}) in #{location}."
      metadata = { event: "new_device", device: device, location: location }

    when :new_location
      title = "New Location Detected"
      message = "Your account was accessed from #{location}, which is different from your usual locations."
      metadata = { event: "new_location", location: location }

    when :password_changed
      title = "Password Changed"
      message = "Your account password was recently changed. If you didn't do this, contact support immediately."
      metadata = { event: "password_changed" }

    when :email_changed
      title = "Email Address Changed"
      message = "Your account email address was recently changed. If you didn't do this, contact support immediately."
      metadata = { event: "email_changed" }

    when :phone_changed
      title = "Phone Number Changed"
      message = "Your account phone number was recently changed. If you didn't do this, contact support immediately."
      metadata = { event: "phone_changed" }

    when :unusual_pattern
      title = "Unusual Activity Detected"
      message = "Our security system detected unusual patterns on your account. Please review recent activity."
      metadata = { event: "unusual_pattern" }

    when :potential_fraud
      title = "Security Alert: Potential Fraud"
      message = "Suspicious activity detected on your account. Please contact support immediately."
      metadata = { event: "potential_fraud" }

    else
      title = "Security Alert"
      message = "A security event was detected on your account. Please review your recent activity."
      metadata = { event: event_type.to_s }
    end

    [ title, message, metadata ]
  end

  # Determine if notification is needed based on severity and user preferences
  # @param severity [Integer] Severity level
  # @param user [User] User associated with the event
  # @param context [Hash] Event context
  # @param immediate [Boolean] Whether to force notification
  # @return [Boolean] True if notification should be sent
  def determine_if_notification_needed(severity, user, context, immediate)
    # Always notify for critical or high severity
    return true if severity >= SEVERITY_LEVELS[:high]

    # Always notify if immediate flag is set
    return true if immediate

    # Check user preferences for medium/low severity alerts
    if user.respond_to?(:notification_preferences) && user.notification_preferences.present?
      # Map our severity to notification preference setting
      pref_severity = case severity
      when SEVERITY_LEVELS[:medium]
                       :warning
      else
                       :info
      end

      # Check if user wants security notifications at this level
      return user.notification_preferences.enabled_for?(:security, pref_severity)
    end

    # Default to notifying for medium but not low
    severity >= SEVERITY_LEVELS[:medium]
  end

  # Log security event to SecurityLog
  # @param user [User] User associated with the event
  # @param event_type [Symbol] Type of security event
  # @param severity [Integer] Severity level
  # @param alert_data [Hash] Alert data
  # @param context [Hash] Event context including IP, user agent, etc.
  # @return [SecurityLog] The created security log
  def log_security_event(user, event_type, severity, alert_data, context)
    # Map to SecurityLog event type
    log_event_type = case event_type
    when :successful_login then :login_success
    when :failed_login, :multiple_failed_logins then :login_failure
    when :password_changed then :password_change
    when :unusual_transaction, :large_transaction,
                          :suspicious_transaction, :potential_fraud then :transaction_check
    when :transaction_blocked then :transaction_blocked
    when :new_device, :new_location, :unusual_time,
                          :unusual_pattern, :unusual_ip then :suspicious_activity
    else :suspicious_activity
    end

    # Map severity
    log_severity = case severity
    when SEVERITY_LEVELS[:critical] then :critical
    when SEVERITY_LEVELS[:high] then :critical
    when SEVERITY_LEVELS[:medium] then :warning
    else :info
    end

    # Get loggable object if applicable
    loggable = nil
    if context[:transaction_id].present?
      loggable = Transaction.find_by(id: context[:transaction_id])
    end

    # Create security log entry
    SecurityLog.log_event(
      user,
      log_event_type,
      severity: log_severity,
      details: alert_data.merge(context),
      ip_address: context[:ip_address],
      user_agent: context[:user_agent],
      loggable: loggable
    )
  end

  # Build alert data from event and context
  # @param event_type [Symbol] Type of security event
  # @param user [User] User associated with the event
  # @param context [Hash] Event context
  # @return [Hash] Structured alert data
  def build_alert_data(event_type, user, context)
    # Start with basic alert data
    data = {
      event_type: event_type,
      timestamp: Time.current,
      user_id: user.id
    }

    # Add location data if available
    if context[:ip_address].present?
      # In a real implementation, this would use a geolocation service
      data[:location] = extract_location(context[:ip_address]) || "unknown location"
    end

    # Add device info if available
    if context[:user_agent].present?
      data[:device_type] = extract_device_type(context[:user_agent])
    end

    # Add time of occurrence
    data[:time] = Time.current

    # Add transaction details if relevant
    if context[:transaction_id].present?
      if defined?(Transaction) && (transaction = Transaction.find_by(id: context[:transaction_id]))
        data[:transaction_type] = transaction.transaction_type
        data[:amount] = transaction.formatted_amount
        data[:payment_method] = transaction.payment_method
      end
    end

    # Add any additional event-specific context
    case event_type
    when :multiple_failed_logins
      data[:attempts] = context[:attempts] || SecurityLog.where(user_id: user.id)
                                                      .where(event_type: :login_failure)
                                                      .where("created_at > ?", 30.minutes.ago)
                                                      .count
    when :unusual_transaction
      data[:reason] = context[:reason] || "Unusual transaction pattern detected"
    end

    data
  end

  # Determine action URL based on event type
  # @param event_type [Symbol] Type of security event
  # @return [String] URL for notification action
  def determine_action_url(event_type)
    case event_type
    when :successful_login, :failed_login, :multiple_failed_logins,
         :new_device, :new_location, :unusual_time, :unusual_ip
      "/settings/security/activity"
    when :unusual_transaction, :large_transaction, :transaction_blocked
      "/wallet/transactions"
    when :password_changed, :email_changed, :phone_changed
      "/settings/security"
    else
      "/settings/security"
    end
  end

  # Extract location information from IP address
  # In a real implementation, this would use a geolocation service
  # @param ip_address [String] IP address
  # @return [String] Human readable location
  def extract_location(ip_address)
    return "unknown location" unless ip_address.present?

    # In a real implementation, this would call a geolocation service
    # Example: GeoIP.lookup(ip_address)

    # For demo purposes, return a placeholder
    "Accra, Ghana"
  end

  # Extract device type from user agent string
  # @param user_agent [String] User agent string
  # @return [String] Human readable device type
  def extract_device_type(user_agent)
    return "unknown device" unless user_agent.present?

    # Simple user agent detection for common device types
    # In a real implementation, this would be more sophisticated
    if user_agent =~ /iPhone|iPad/i
      "iOS device"
    elsif user_agent =~ /Android/i
      "Android device"
    elsif user_agent =~ /Windows Phone/i
      "Windows Phone"
    elsif user_agent =~ /Windows NT/i
      "Windows computer"
    elsif user_agent =~ /Macintosh/i
      "Mac computer"
    elsif user_agent =~ /Linux/i
      "Linux computer"
    else
      "unknown device"
    end
  end

  # Mock IP intelligence check for demo purposes
  # In a real implementation, this would call a third-party API
  # @param ip_address [String] IP address to check
  # @return [Hash] IP reputation data
  def mock_ip_intelligence_check(ip_address)
    # For demo purposes, return suspicious for IPs ending in .99
    is_suspicious = ip_address.end_with?(".99")

    {
      ip: ip_address,
      suspicious: is_suspicious,
      risk_score: is_suspicious ? 85 : 15,
      country: "Ghana",
      city: "Accra",
      isp: "Demo ISP",
      is_proxy: false,
      is_tor: false,
      timestamps: Time.current
    }
  end

  # Mock device intelligence check for demo purposes
  # In a real implementation, this would call a third-party API
  # @param device_fingerprint [String] Device fingerprint to check
  # @return [Hash] Device reputation data
  def mock_device_intelligence_check(device_fingerprint)
    # For demo purposes, return suspicious for fingerprints containing "suspicious"
    is_suspicious = device_fingerprint.to_s.include?("suspicious")

    {
      fingerprint: device_fingerprint,
      suspicious: is_suspicious,
      risk_score: is_suspicious ? 75 : 20,
      known_fraud: false,
      device_age_days: 30,
      first_seen_at: 30.days.ago,
      associated_accounts: is_suspicious ? 5 : 1,
      emulation_detected: false,
      timestamps: Time.current
    }
  end
end
