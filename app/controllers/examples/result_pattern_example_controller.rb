module Examples
  # Example controller that demonstrates the Result pattern with ResultHandler
  # This is for reference only and not used in production
  class ResultPatternExampleController < ApplicationController
    include ResultHandler

    # Example action with basic result handling
    def create
      result = Examples::ResultPatternExampleService.new.perform_operation(example_params)
      
      handle_result(result, {
        success_message: "Operation completed successfully",
        success_redirect: examples_path,
        failure_action: :render,
        render_options: { action: :new }
      })
    end

    # Example action with more advanced result handling
    def process
      result = Examples::ResultPatternExampleService.new.perform_multi_step_operation(example_params)
      
      handle_result(result, {
        success_message: "Multi-step operation completed successfully",
        success_action: :json,
        failure_action: :json
      }) do |data|
        # This block is executed on success and can perform additional actions
        # Log the successful operation
        Rails.logger.info("Successfully processed multi-step operation: #{data[:reference]}")
        
        # Could trigger additional actions
        # NotificationService.notify_admin(data)
      end
    end

    # Example action showing conditional handling
    def update
      result = Examples::ResultPatternExampleService.new.perform_operation(example_params)
      
      if result.success?
        data = result.data
        
        # Check if this is a special case
        if data[:processed_data][:special_case]
          # Handle special case differently
          redirect_to special_processing_path(data[:processed_data][:reference]), 
                      notice: "Special case processing initiated!"
        else
          # Normal success handling
          redirect_to example_path(data[:processed_data][:reference]), 
                      notice: "Operation completed successfully!"
        end
      else
        # Error handling
        flash.now[:alert] = result.error_message
        
        # Check for specific error cases
        if result.error_code?(:validation_error)
          # Handle validation errors
          @errors = result.error_details
          render :edit
        elsif result.error_code?(:insufficient_funds)
          # Handle insufficient funds errors
          redirect_to add_funds_path, alert: "Please add funds to continue"
        else
          # General error fallback
          render :edit
        end
      end
    end

    # Example JSON API endpoint
    def api_operation
      result = Examples::ResultPatternExampleService.new.perform_operation(example_params)
      
      if result.success?
        render json: {
          success: true,
          data: result.data[:processed_data],
          message: "Operation completed successfully"
        }
      else
        render json: {
          success: false,
          error: {
            message: result.error_message,
            code: result.error_code,
            details: