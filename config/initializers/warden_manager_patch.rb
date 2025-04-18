# This initializer patches Warden::Manager to handle invalid strategies gracefully

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
  if defined?(Warden) && defined?(Warden::Manager)
    # Check if the run_strategies method exists (it might have a different name in different versions)
    if Warden::Manager.instance_methods.include?(:run_strategies)
      unless Warden::Manager.method_defined?(:_original_run_strategies)
        Warden::Manager.class_eval do
          alias_method :_original_run_strategies, :run_strategies

          def run_strategies(scope, args = {})
            begin
              _original_run_strategies(scope, args)
            rescue => e
              safe_log(:error, "Error running Warden strategies for scope #{scope}: #{e.message}")
              nil # Return nil instead of raising an error
            end
          end
        end

        safe_log(:info, "Patched Warden::Manager to handle invalid strategies")
      end
    else
      safe_log(:warn, "Could not patch Warden::Manager - run_strategies method not found")
    end
  end
end
