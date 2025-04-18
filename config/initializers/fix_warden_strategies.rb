# This initializer fixes issues with missing Warden strategies
# It runs after Devise is initialized to ensure all dependencies are available

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
    if defined?(Warden)
      safe_log(:info, "Checking Warden strategies...")

      # Check if the some_external_strategy is registered
      if defined?(Warden::Strategies) && Warden::Strategies.respond_to?(:[]) && !Warden::Strategies[:some_external_strategy]
        begin
          # Try to load our placeholder strategy
          require_relative "../../lib/strategies/some_external_strategy"

          # Register the strategy with Warden if the class is defined
          if defined?(Devise::Strategies::SomeExternalStrategy)
            Warden::Strategies.add(:some_external_strategy, Devise::Strategies::SomeExternalStrategy)
            safe_log(:info, "Registered placeholder SomeExternalStrategy")
          else
            # As a last resort, create an anonymous strategy
            Warden::Strategies.add(:some_external_strategy) do
              def valid?
                false # This strategy is never valid, so it won't be used
              end

              def authenticate!
                fail!("Placeholder strategy")
              end
            end

            safe_log(:info, "Registered anonymous placeholder strategy")
          end
        rescue => e
          safe_log(:error, "Failed to register placeholder strategy: #{e.message}")
        end
      end

      # Patch Warden Manager to handle missing strategies gracefully
      if defined?(Warden::Manager)
        # Check if the run_strategies method exists
        if Warden::Manager.instance_methods.include?(:run_strategies)
          unless Warden::Manager.method_defined?(:_original_run_strategies)
            Warden::Manager.class_eval do
              alias_method :_original_run_strategies, :run_strategies

              def run_strategies(scope, args = {})
                begin
                  _original_run_strategies(scope, args)
                rescue => e
                  safe_log(:error, "Error running Warden strategies: #{e.message}")
                  nil # Return nil instead of raising an error
                end
              end
            end

            safe_log(:info, "Patched Warden Manager to handle missing strategies")
          end
        else
          safe_log(:warn, "Could not patch Warden::Manager - run_strategies method not found")
        end
      end
    end
  rescue => e
    safe_log(:error, "Error in fix_warden_strategies: #{e.message}")
    safe_log(:error, e.backtrace.join("\n")) if e.backtrace
  end
end
