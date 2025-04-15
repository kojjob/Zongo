# This initializer removes the invalid 'some_external_strategy' from the default strategies

# Define a safe logging method that works even before Rails is fully initialized
def safe_log(level, message)
  if defined?(Rails) && Rails.logger
    Rails.logger.send(level, message)
  else
    # Fallback to puts for early loading
    puts "[#{level.to_s.upcase}] #{message}"
  end
end

# We'll use after_initialize to ensure Rails is fully loaded
Rails.application.config.after_initialize do
  begin
    if defined?(Warden) && defined?(Warden::Manager)
      # Get all Warden Manager instances
      ObjectSpace.each_object(Warden::Manager) do |manager|
        # Check if this manager has default strategies
        if manager.respond_to?(:default_strategies) && manager.default_strategies.is_a?(Hash)
          # For each scope in the default strategies
          manager.default_strategies.each do |scope, strategies|
            if strategies.is_a?(Array) && strategies.include?(:some_external_strategy)
              # Remove the invalid strategy
              strategies.delete(:some_external_strategy)
              safe_log(:info, "Removed invalid strategy 'some_external_strategy' from scope #{scope}")
            end
          end
        end
      end
    end
  rescue => e
    safe_log(:error, "Error removing invalid strategy: #{e.message}")
    safe_log(:error, e.backtrace.join("\n")) if e.backtrace
  end
end
