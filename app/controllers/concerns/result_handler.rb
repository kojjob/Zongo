module ResultHandler
  extend ActiveSupport::Concern

  # Handle a Result object with different responses for success/failure
  # @param result [Result] The result object to handle
  # @param options [Hash] Options for handling the result
  # @option options [String] :success_message Message to display on success
  # @option options [String] :failure_message Message to display on failure
  # @option options [String, Symbol] :success_redirect Where to redirect on success
  # @option options [String, Symbol] :failure_redirect Where to redirect on failure
  # @option options [Symbol] :success_action Action to perform on success (:render, :redirect, :json)
  # @option options [Symbol] :failure_action Action to perform on failure (:render, :redirect, :json)
  # @option options [Boolean] :use_toastr Whether to use toastr for notifications
  # @yield [data] Block to execute on success with the result data
  # @return [Object] The result of the chosen action
  def handle_result(result, options = {})
    if result.success?
      handle_success(result, options)
    else
      handle_failure(result, options)
    end
  end

  # Handle a successful result
  # @param result [Result] The successful result object
  # @param options [Hash] Options for handling the result
  # @return [Object] The result of the chosen action
  def handle_success(result, options = {})
    # Execute success block if provided
    yield(result.data) if block_given?

    # Get success message from options or result data
    message = options[:success_message] || 
              (result.data.is_a?(Hash) && result.data[:message]) || 
              "Operation completed successfully"

    # Determine the action to take
    case options[:success_action]&.to_sym
    when :json
      render json: { success: true, data: result.data, message: message }
    when :render
      # Add flash message unless explicitly disabled
      flash[:notice] = message unless options[:skip_flash]
      
      # If render options are provided, use them
      if options[:render_options].present?
        render options[:render_options]
      else
        # Default to rendering current action
      end
    else # Default to redirect
      flash[:notice] = message unless options[:skip_flash]
      
      if options[:success_redirect].present?
        redirect_to options[:success_redirect]
      else
        # Try to redirect to a sensible default based on controller/action
        redirect_to(determine_default_redirect || { action: :index })
      end
    end
  end

  # Handle a failed result
  # @param result [Result] The failed result object
  # @param options [Hash] Options for handling the result
  # @return [Object] The result of the chosen action
  def handle_failure(result, options = {})
    # Get error message from options, result, or default
    message = options[:failure_message] || result.error_message || "Operation failed"
    
    # Get error code and details for logging
    code = result.error_code
    details = result.error_details

    # Log the error
    Rails.logger.error("Error in #{controller_name}##{action_name}: #{message} (#{code})")
    Rails.logger.error("Error details: #{details.inspect}") if details.present?

    # Determine the action to take
    case options[:failure_action]&.to_sym
    when :json
      render json: { 
        success: false, 
        error: {
          message: message,
          code: code,
          details: details
        }
      }, status: determine_status_code(code)
    when :render
      # Add flash message unless explicitly disabled
      flash[:alert] = message unless options[:skip_flash]
      
      # Set error for use in view
      @error = {
        message: message,
        code: code,
        details: details
      }
      
      if options[:render_options].present?
        render options[:render_options]
      else
        # Default to rendering current action
        render action: action_name
      end
    else # Default to redirect
      flash[:alert] = message unless options[:skip_flash]
      
      if options[:failure_redirect].present?
        redirect_to options[:failure_redirect]
      else
        # Try to redirect to a sensible default based on error
        redirect_to(determine_failure_redirect(code) || { action: :index })
      end
    end
  end

  private

  # Determine the appropriate HTTP status code based on error code
  # @param code [Symbol] The error code
  # @return [Symbol] The HTTP status code
  def determine_status_code(code)
    case code
    when :not_found
      :not_found
    when :validation_error, :invalid_params
      :unprocessable_entity
    when :authentication_error, :unauthorized
      :unauthorized
    when :forbidden, :access_denied
      :forbidden
    when :concurrency_error, :conflict
      :conflict
    when :external_service_error
      :service_unavailable
    when :too_many_requests
      :too_many_requests
    else
      :bad_request
    end
  end

  # Determine a default redirect based on controller and action
  # @return [String, Hash, nil] The redirect destination or nil
  def determine_default_redirect
    case action_name
    when 'create'
      if @resource.present? && @resource.respond_to?(:persisted?) && @resource.persisted?
        return { action: :show, id: @resource.id }
      else
        return { action: :index }
      end
    when 'update'
      if @resource.present? && @resource.respond_to?(:id)
        return { action: :show, id: @resource.id }
      else
        return { action: :index }
      end
    when 'destroy'
      return { action: :index }
    else
      nil
    end
  end

  # Determine a failure redirect based on error code
  # @param code [Symbol] The error code
  # @return [String, Hash, nil] The redirect destination or nil
  def determine_failure_redirect(code)
    case code
    when :not_found
      { action: :index }
    when :authentication_error, :unauthorized
      main_app.new_user_session_path if defined?(main_app) && main_app.respond_to?(:new_user_session_path)
    when :insufficient_funds
      main_app.wallet_path if defined?(main_app) && main_app.respond_to?(:wallet_path)
    else
      nil
    end
  end
end
