class SecurityMonitoringService
  # Third-party services to integrate with
  AVAILABLE_SERVICES = {
    slack: {
      enabled: true,
      webhook_url: ENV["SECURITY_SLACK_WEBHOOK_URL"]
    },
    pagerduty: {
      enabled: Rails.env.production?,
      api_key: ENV["PAGERDUTY_API_KEY"],
      service_id: ENV["PAGERDUTY_SECURITY_SERVICE_ID"]
    },
    sentry: {
      enabled: Rails.env.production?,
      dsn: ENV["SENTRY_DSN"]
    },
    newrelic: {
      enabled: Rails.env.production?,
      api_key: ENV["NEWRELIC_API_KEY"]
    }
  }

  # Initialize the security monitoring service
  # @param services [Array<Symbol>] List of services to enable
  def initialize(services: [ :slack ])
    @services = services.select { |s| AVAILABLE_SERVICES[s]&.dig(:enabled) }
    @environment = Rails.env
    @app_name = Rails.application.class.module_parent_name
  end

  # Send a security alert to configured monitoring services
  # @param alert_data [Hash] Details of the security alert
  # @param severity [Symbol] Alert severity level
  # @param notify_team [Boolean] Whether to notify the security team
  # @return [Hash] Results of alert delivery to each service
  def send_alert(alert_data, severity: :medium, notify_team: false)
    results = {}

    # Validate and normalize the alert data
    normalized_data = normalize_alert_data(alert_data, severity)

    # Send to each configured service
    @services.each do |service|
      results[service] = case service
      when :slack
                          send_to_slack(normalized_data, notify_team)
      when :pagerduty
                          send_to_pagerduty(normalized_data, notify_team)
      when :sentry
                          send_to_sentry(normalized_data)
      when :newrelic
                          send_to_newrelic(normalized_data)
      end
    end

    # Log the alert
    log_security_alert(normalized_data, results)

    results
  end

  # Check if a service is available and configured
  # @param service [Symbol] The service to check
  # @return [Boolean] True if the service is available
  def service_available?(service)
    AVAILABLE_SERVICES[service]&.dig(:enabled) && @services.include?(service)
  end

  private

  # Normalize alert data to a standard format
  # @param alert_data [Hash] Raw alert data
  # @param severity [Symbol] Alert severity level
  # @return [Hash] Normalized alert data
  def normalize_alert_data(alert_data, severity)
    # Ensure required fields are present
    raise ArgumentError, "Alert data must include a title" unless alert_data[:title].present?

    # Create a normalized alert hash
    {
      title: alert_data[:title],
      description: alert_data[:description] || alert_data[:message] || "Security alert detected",
      severity: severity,
      source: alert_data[:source] || "security_monitoring",
      timestamp: Time.current,
      environment: @environment,
      app_name: @app_name,
      details: alert_data,
      user_id: alert_data[:user_id],
      alert_id: SecureRandom.uuid
    }
  end

  # Send alert to Slack
  # @param alert_data [Hash] Normalized alert data
  # @param notify_team [Boolean] Whether to notify the security team
  # @return [Boolean] Success status
  def send_to_slack(alert_data, notify_team)
    return false unless service_available?(:slack)

    begin
      webhook_url = AVAILABLE_SERVICES[:slack][:webhook_url]

      # Prepare the message attachment
      attachment = {
        fallback: "Security Alert: #{alert_data[:title]}",
        color: severity_to_color(alert_data[:severity]),
        title: alert_data[:title],
        text: alert_data[:description],
        fields: [
          {
            title: "Severity",
            value: alert_data[:severity].to_s.upcase,
            short: true
          },
          {
            title: "Environment",
            value: alert_data[:environment],
            short: true
          }
        ],
        footer: "#{alert_data[:app_name]} Security Monitoring",
        ts: alert_data[:timestamp].to_i
      }

      # Add user information if available
      if alert_data[:user_id].present?
        user = User.find_by(id: alert_data[:user_id])
        if user
          attachment[:fields] << {
            title: "User",
            value: "#{user.email} (ID: #{user.id})",
            short: false
          }
        end
      end

      # Add notification for high severity
      message_text = if notify_team || [ :high, :critical ].include?(alert_data[:severity])
                      "@security-team Security Alert: #{alert_data[:title]}"
      else
                      "Security Alert: #{alert_data[:title]}"
      end

      # Prepare the payload
      payload = {
        text: message_text,
        attachments: [ attachment ]
      }

      # Send the message
      uri = URI.parse(webhook_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.request_uri)
      request.content_type = "application/json"
      request.body = payload.to_json

      response = http.request(request)
      response.code.to_i == 200
    rescue => e
      Rails.logger.error("Failed to send Slack alert: #{e.message}")
      false
    end
  end

  # Send alert to PagerDuty
  # @param alert_data [Hash] Normalized alert data
  # @param notify_team [Boolean] Whether to notify the security team
  # @return [Boolean] Success status
  def send_to_pagerduty(alert_data, notify_team)
    return false unless service_available?(:pagerduty)

    # Only trigger PagerDuty for high severity or when explicitly requested
    return false unless notify_team || [ :high, :critical ].include?(alert_data[:severity])

    begin
      api_key = AVAILABLE_SERVICES[:pagerduty][:api_key]
      service_id = AVAILABLE_SERVICES[:pagerduty][:service_id]

      # Prepare the payload
      payload = {
        routing_key: api_key,
        event_action: "trigger",
        payload: {
          summary: alert_data[:title],
          source: "#{@app_name}:#{@environment}",
          severity: pagerduty_severity(alert_data[:severity]),
          timestamp: alert_data[:timestamp].iso8601,
          custom_details: alert_data[:details]
        },
        links: [
          {
            href: "#{ENV['APP_URL']}/admin/security/alerts/#{alert_data[:alert_id]}",
            text: "View Alert Details"
          }
        ]
      }

      # Send the request
      uri = URI.parse("https://events.pagerduty.com/v2/enqueue")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.request_uri)
      request.content_type = "application/json"
      request.body = payload.to_json

      response = http.request(request)
      JSON.parse(response.body)["status"] == "success"
    rescue => e
      Rails.logger.error("Failed to send PagerDuty alert: #{e.message}")
      false
    end
  end

  # Send alert to Sentry
  # @param alert_data [Hash] Normalized alert data
  # @return [Boolean] Success status
  def send_to_sentry(alert_data)
    return false unless service_available?(:sentry)

    begin
      # Prepare event data
      event_data = {
        level: sentry_level(alert_data[:severity]),
        transaction: "security.alert",
        message: alert_data[:title],
        extra: alert_data[:details],
        tags: {
          alert_type: alert_data[:source],
          environment: @environment,
          severity: alert_data[:severity].to_s
        },
        user: alert_data[:user_id].present? ? { id: alert_data[:user_id] } : nil
      }

      # Send to Sentry
      Raven.capture_message(
        alert_data[:description],
        extra: event_data[:extra],
        level: event_data[:level],
        tags: event_data[:tags],
        user: event_data[:user]
      )

      true
    rescue => e
      Rails.logger.error("Failed to send Sentry alert: #{e.message}")
      false
    end
  end

  # Send alert to New Relic
  # @param alert_data [Hash] Normalized alert data
  # @return [Boolean] Success status
  def send_to_newrelic(alert_data)
    return false unless service_available?(:newrelic)

    begin
      # Log custom event to New Relic
      if defined?(::NewRelic)
        ::NewRelic::Agent.record_custom_event(
          "SecurityAlert",
          {
            title: alert_data[:title],
            description: alert_data[:description],
            severity: alert_data[:severity].to_s,
            source: alert_data[:source],
            user_id: alert_data[:user_id],
            alert_id: alert_data[:alert_id],
            timestamp: alert_data[:timestamp].to_i
          }
        )

        true
      else
        false
      end
    rescue => e
      Rails.logger.error("Failed to send New Relic alert: #{e.message}")
      false
    end
  end

  # Log security alert to application logs
  # @param alert_data [Hash] Normalized alert data
  # @param delivery_results [Hash] Results of alert delivery
  # @return [void]
  def log_security_alert(alert_data, delivery_results)
    log_data = {
      alert_id: alert_data[:alert_id],
      title: alert_data[:title],
      severity: alert_data[:severity],
      timestamp: alert_data[:timestamp],
      delivery: delivery_results
    }

    case alert_data[:severity]
    when :critical
      Rails.logger.error("SECURITY CRITICAL: #{log_data.to_json}")
    when :high
      Rails.logger.error("SECURITY ALERT: #{log_data.to_json}")
    when :medium
      Rails.logger.warn("SECURITY WARNING: #{log_data.to_json}")
    else
      Rails.logger.info("SECURITY INFO: #{log_data.to_json}")
    end
  end

  # Convert severity to Slack color
  # @param severity [Symbol] Alert severity
  # @return [String] Slack color code
  def severity_to_color(severity)
    case severity
    when :critical then "danger"
    when :high then "danger"
    when :medium then "warning"
    when :low then "good"
    else "#439FE0" # Blue for info
    end
  end

  # Convert severity to PagerDuty severity
  # @param severity [Symbol] Alert severity
  # @return [String] PagerDuty severity level
  def pagerduty_severity(severity)
    case severity
    when :critical then "critical"
    when :high then "error"
    when :medium then "warning"
    when :low then "info"
    else "info"
    end
  end

  # Convert severity to Sentry level
  # @param severity [Symbol] Alert severity
  # @return [String] Sentry level
  def sentry_level(severity)
    case severity
    when :critical then "fatal"
    when :high then "error"
    when :medium then "warning"
    when :low then "info"
    else "info"
    end
  end
end
