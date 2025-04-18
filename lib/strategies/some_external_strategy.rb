# Define a safe logging method that works even before Rails is fully initialized
def safe_log(level, message)
  if defined?(Rails) && Rails.logger
    Rails.logger.send(level, message)
  else
    # Fallback to puts for early loading
    puts "[#{level.to_s.upcase}] #{message}"
  end
end

begin
  require "devise/strategies/base"

  module Devise
    module Strategies
      # This is a placeholder strategy to replace the missing 'some_external_strategy'
      # It will always pass to the next strategy in the chain without failing
      class SomeExternalStrategy < Devise::Strategies::Base
        def valid?
          # This strategy is always considered valid so it can be executed
          true
        end

        def authenticate!
          # Log that this placeholder strategy was called
          safe_log(:debug, "Placeholder SomeExternalStrategy was called - passing to next strategy")

          # Pass to the next strategy without failing
          # This allows the authentication to continue with other strategies
          pass
        end

        # Handle any errors that might occur
        def self.serialize_from_session(*args)
          begin
            super
          rescue => e
            safe_log(:error, "Error in SomeExternalStrategy.serialize_from_session: #{e.message}")
            nil
          end
        end

        def self.serialize_into_session(*args)
          begin
            super
          rescue => e
            safe_log(:error, "Error in SomeExternalStrategy.serialize_into_session: #{e.message}")
            nil
          end
        end
      end
    end
  end

  # Register the strategy with Warden
  if defined?(Warden) && !Warden::Strategies[:some_external_strategy]
    Warden::Strategies.add(:some_external_strategy, Devise::Strategies::SomeExternalStrategy)
    safe_log(:info, "Registered placeholder SomeExternalStrategy")
  end
rescue => e
  # If anything goes wrong, log it but don't crash
  safe_log(:error, "Error setting up SomeExternalStrategy: #{e.message}")
  safe_log(:error, e.backtrace.join("\n")) if e.backtrace
end
