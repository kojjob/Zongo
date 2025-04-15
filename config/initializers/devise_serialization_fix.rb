# Fix Devise Serialization to ensure User objects, not Hashes

# Define a safe logging method that works even before Rails is fully initialized
def safe_log(level, message)
  if defined?(Rails) && Rails.logger
    Rails.logger.send(level, message)
  else
    # Fallback to puts for early loading
    puts "[#{level.to_s.upcase}] #{message}"
  end
end

# Use after_initialize to ensure Rails is fully loaded
Rails.application.config.after_initialize do
  begin
    if defined?(Devise)
      Devise.setup do |config|
        # Override the default behavior to make sure we're always storing and retrieving User objects properly
        config.warden do |manager|
          # When serializing to the session, just store the ID and class name
          manager.serialize_into_session do |user|
            safe_log(:debug, "Serializing user to session: #{user.class.name} #{user.id}")
            [user.class.name, user.id]
          end

          # When retrieving from the session, properly find the User object
          manager.serialize_from_session do |key|
            begin
              klass = key.first.constantize
              user_id = key.last
              safe_log(:debug, "Deserializing user from session: #{klass} #{user_id}")

              user = klass.find_by(id: user_id)
              if user.nil?
                safe_log(:warn, "Could not find User with ID #{user_id}")
              end
              user
            rescue => e
              safe_log(:error, "Error deserializing user from session: #{e.message}")
              nil
            end
          end
        end
      end
    end
  rescue => e
    safe_log(:error, "Error in devise_serialization_fix.rb: #{e.message}")
    safe_log(:error, e.backtrace.join("\n")) if e.backtrace
  end
end
