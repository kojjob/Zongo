# This initializer patches Warden::Proxy to handle invalid strategies gracefully

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
  if defined?(Warden) && defined?(Warden::Proxy)
    begin
      # Only patch if the methods exist
      if Warden::Proxy.instance_methods.include?(:authenticate!) &&
         Warden::Proxy.instance_methods.include?(:user)

        unless Warden::Proxy.method_defined?(:_original_authenticate)
          Warden::Proxy.class_eval do
            alias_method :_original_authenticate, :authenticate!

            def authenticate!(*args)
              begin
                _original_authenticate(*args)
              rescue => e
                safe_log(:error, "Error in Warden authentication: #{e.message}")
                nil # Return nil instead of raising an error
              end
            end

            alias_method :_original_user, :user

            def user(scope = nil)
              begin
                _original_user(scope)
              rescue => e
                safe_log(:error, "Error retrieving Warden user: #{e.message}")
                nil # Return nil instead of raising an error
              end
            end
          end

          safe_log(:info, "Patched Warden::Proxy to handle errors gracefully")
        end
      else
        safe_log(:warn, "Could not patch Warden::Proxy - required methods not found")
      end
    rescue => e
      safe_log(:error, "Error patching Warden::Proxy: #{e.message}")
    end
  end
end
