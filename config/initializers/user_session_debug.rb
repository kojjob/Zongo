# Debug User Serialization Issues

# Define a safe logging method that works even before Rails is fully initialized
def safe_log(level, message)
  if defined?(Rails) && Rails.logger
    Rails.logger.send(level, message)
  else
    # Fallback to puts for early loading
    puts "[#{level.to_s.upcase}] #{message}"
  end
end

Rails.application.config.after_initialize do
  begin
    if defined?(Warden) && defined?(Warden::Manager)
      # Add debug output when storing the user in the session
      Warden::Manager.after_set_user do |user, auth, opts|
        if user.is_a?(Hash)
          safe_log(:warn, "WARNING: Warden is storing a Hash instead of a User object in the session!")
          safe_log(:warn, "User Hash: #{user.inspect}")
          safe_log(:warn, "Authentication info: #{auth.inspect}")
          safe_log(:warn, "Options: #{opts.inspect}")
          safe_log(:warn, "Backtrace: #{caller[0..5].join("\n")}")
        end
      end
    end
  rescue => e
    safe_log(:error, "Error in user_session_debug.rb: #{e.message}")
    safe_log(:error, e.backtrace.join("\n")) if e.backtrace
  end
end
