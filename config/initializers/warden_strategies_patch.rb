# This initializer patches Warden::Strategies to handle invalid strategies gracefully

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
  if defined?(Warden) && defined?(Warden::Strategies)
    begin
      # Check if the [] method exists
      if Warden::Strategies.singleton_class.instance_methods.include?(:[]) ||
         Warden::Strategies.respond_to?(:[])

        unless Warden::Strategies.singleton_class.method_defined?(:_original_fetch)
          Warden::Strategies.singleton_class.class_eval do
            alias_method :_original_fetch, :[]

            def [](strategy)
              begin
                _original_fetch(strategy)
              rescue => e
                safe_log(:error, "Error fetching strategy #{strategy}: #{e.message}")

                # Only create a dummy strategy if Warden::Strategies::Base is defined
                if defined?(Warden::Strategies::Base)
                  # Create and register a dummy strategy on the fly
                  dummy_strategy = Class.new(Warden::Strategies::Base) do
                    def valid?
                      false # Never valid, so it won't be used
                    end

                    def authenticate!
                      fail!("Dummy strategy for #{strategy}")
                    end
                  end

                  # Register the dummy strategy
                  Warden::Strategies.add(strategy, dummy_strategy)

                  # Return the newly registered strategy
                  _original_fetch(strategy)
                else
                  safe_log(:warn, "Cannot create dummy strategy - Warden::Strategies::Base not defined")
                  nil
                end
              end
            end
          end

          safe_log(:info, "Patched Warden::Strategies to handle invalid strategies")
        end
      else
        safe_log(:warn, "Could not patch Warden::Strategies - [] method not found")
      end
    rescue => e
      safe_log(:error, "Error patching Warden::Strategies: #{e.message}")
      safe_log(:error, e.backtrace.join("\n")) if e.backtrace
    end
  end
end
