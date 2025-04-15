# Load custom Warden strategies
# We'll load the strategy in the after_initialize hook instead of here
# to ensure Rails is fully initialized

# Define a safe logging method that works even before Rails is fully initialized
def safe_log(level, message)
  if defined?(Rails) && Rails.logger
    Rails.logger.send(level, message)
  else
    # Fallback to puts for early loading
    puts "[#{level.to_s.upcase}] #{message}"
  end
end

# Make sure the strategy is properly registered
Rails.application.config.after_initialize do
  begin
    # Ensure our strategy is available
    if defined?(Warden) && defined?(Warden::Strategies) && Warden::Strategies.respond_to?(:[]) && !Warden::Strategies[:some_external_strategy]
      safe_log(:warn, "Registering placeholder SomeExternalStrategy from warden_strategies.rb")

      # Load the strategy
      begin
        require_relative '../../lib/strategies/some_external_strategy'

        # Register the strategy if it's defined
        if defined?(Devise::Strategies::SomeExternalStrategy)
          Warden::Strategies.add(:some_external_strategy, Devise::Strategies::SomeExternalStrategy)
        else
          safe_log(:warn, "SomeExternalStrategy class not defined")
        end
      rescue => e
        safe_log(:error, "Error loading SomeExternalStrategy: #{e.message}")
      end
    end
  rescue => e
    safe_log(:error, "Error in warden_strategies.rb: #{e.message}")
  end
end
