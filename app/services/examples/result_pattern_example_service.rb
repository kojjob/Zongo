module Examples
  # Example service that demonstrates the Result pattern
  # This is for reference only and not used in production
  class ResultPatternExampleService
    attr_reader :errors

    def initialize
      @errors = []
    end

    # Example method demonstrating success path
    # @param params [Hash] The input parameters
    # @return [Result] A Result object with success or failure
    def perform_operation(params)
      # Validate inputs
      validation_result = validate_params(params)
      return validation_result if validation_result.failure?

      # Extract validated data
      data = validation_result.data

      # Perform the operation (example)
      begin
        # Simulate a DB operation or external API call
        processed_data = process_data(data)
        
        # Return success result with the processed data
        Result.success({
          message: "Operation completed successfully",
          processed_data: processed_data
        })
      rescue StandardError => e
        # Log the error
        Rails.logger.error("Error performing operation: #{e.message}")
        
        # Return a failure result
        Result.failure({
          message: "Failed to perform operation",
          code: :operation_failed,
          details: e.message
        })
      end
    end

    # Example method demonstrating chaining operations
    # @param params [Hash] The input parameters
    # @return [Result] A Result object with success or failure
    def perform_multi_step_operation(params)
      # Step 1: Validate and prepare data
      validate_params(params)
        .and_then { |data| prepare_data(data) }
        .and_then { |data| process_data(data) }
        .and_then { |data| finalize_data(data) }
        .map { |data| format_output(data) }
    end

    private

    # Validate input parameters
    # @param params [Hash] The input parameters
    # @return [Result] A Result object with validation result
    def validate_params(params)
      # Check if params exist
      return Result.failure(ValidationError.new("No parameters provided")) if params.nil?
      
      # Check required fields
      if params[:name].blank?
        return Result.failure({
          message: "Name is required",
          code: :validation_error,
          details: { name: ["can't be blank"] }
        })
      end

      if params[:email].blank?
        return Result.failure({
          message: "Email is required",
          code: :validation_error,
          details: { email: ["can't be blank"] }
        })
      end

      # Validate email format (simplified)
      unless params[:email] =~ /\A[^@\s]+@[^@\s]+\z/
        return Result.failure({
          message: "Invalid email format",
          code: :validation_error,
          details: { email: ["is not valid"] }
        })
      end

      # Return validated data
      Result.success({
        name: params[:name],
        email: params[:email],
        options: params[:options] || {}
      })
    end

    # Prepare data for processing
    # @param data [Hash] The validated data
    # @return [Result] A Result object with prepared data
    def prepare_data(data)
      # Example preparation logic
      prepared_data = {
        name: data[:name].strip,
        email: data[:email].downcase,
        options: data[:options],
        prepared_at: Time.current
      }
      
      Result.success(prepared_data)
    end

    # Process the data
    # @param data [Hash] The data to process
    # @return [Result] A Result object with processed data
    def process_data(data)
      # Example processing logic
      processed_data = data.merge({
        status: "processed",
        processed_at: Time.current,
        reference: SecureRandom.hex(10)
      })

      # Simulate potential failure
      if rand(10) == 0 # 10% chance of failure for demo purposes
        return Result.failure({
          message: "Random processing error occurred",
          code: :processing_error
        })
      end

      Result.success(processed_data)
    end

    # Finalize the data
    # @param data [Hash] The data to finalize
    # @return [Result] A Result object with finalized data
    def finalize_data(data)
      # Example finalization logic
      finalized_data = data.merge({
        completed: true,
        completed_at: Time.current
      })

      Result.success(finalized_data)
    end

    # Format the output data
    # @param data [Hash] The data to format
    # @return [Hash] The formatted data
    def format_output(data)
      # Example output formatting
      {
        name: data[:name],
        email: data[:email],
        reference: data[:reference],
        completed_at: data[:completed_at].iso8601,
        status: "success"
      }
    end
  end
end
