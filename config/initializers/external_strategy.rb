# This initializer ensures the placeholder strategy is loaded after Rails is fully initialized

Rails.application.config.after_initialize do
  # Only load if not already loaded
  unless defined?(Devise::Strategies::SomeExternalStrategy)
    begin
      require_relative "../../lib/strategies/some_external_strategy"
      puts "[INFO] Loaded placeholder SomeExternalStrategy from initializer"
    rescue => e
      puts "[ERROR] Failed to load SomeExternalStrategy: #{e.message}"
      puts e.backtrace.join("\n") if e.backtrace
    end
  end
end
