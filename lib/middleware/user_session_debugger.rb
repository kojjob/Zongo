class UserSessionDebugger
  def initialize(app)
    @app = app
  end

  def call(env)
    # Before request: Check if there's a user in the session
    begin
      if env["rack.session"] && env["rack.session"]["warden.user.user.key"]
        key = env["rack.session"]["warden.user.user.key"]
        Rails.logger.debug "SESSION USER: #{key.inspect}"

        if key.is_a?(Hash)
          Rails.logger.warn "User in session is a Hash! Path: #{env['PATH_INFO']}"
        end
      end
    rescue => e
      Rails.logger.error "Error checking session user: #{e.message}"
    end

    # Process the request
    begin
      status, headers, response = @app.call(env)
    rescue => e
      Rails.logger.error "Error in middleware chain: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      # Return a 500 error response
      return [ 500, { "Content-Type" => "text/html" }, [ "<html><body><h1>Internal Server Error</h1><p>#{e.message}</p></body></html>" ] ]
    end

    # After request: Check if there's a user in the warden
    # Skip this part entirely to avoid the error
    # begin
    #   if env['warden']
    #     begin
    #       # Try to get the user without using strategies
    #       if env['warden'].authenticated?(:user)
    #         user = env['warden'].user(:user)
    #         if user
    #           Rails.logger.debug "WARDEN USER: #{user.class.name} in #{env['PATH_INFO']}"
    #
    #           if user.is_a?(Hash)
    #             Rails.logger.warn "Warden user is a Hash in path: #{env['PATH_INFO']}"
    #           end
    #         end
    #       end
    #     rescue => e
    #       Rails.logger.error "Error accessing warden user: #{e.message}"
    #     end
    #   end
    # rescue => e
    #   Rails.logger.error "Error in post-request warden check: #{e.message}"
    # end

    [ status, headers, response ]
  end
end
