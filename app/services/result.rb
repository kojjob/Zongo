class Result
  attr_reader :success, :data, :error

  def initialize(success, data = nil, error = nil)
    @success = success
    @data = data
    @error = error
  end

  def success?
    @success
  end

  def failure?
    !@success
  end

  # Creates a success result with optional data
  # @param data [Hash, Object] The data to include in the result
  # @return [Result] A new success result
  def self.success(data = nil)
    new(true, data, nil)
  end

  # Creates a failure result with error information
  # @param error [Hash, ServiceError, String] The error information
  # @return [Result] A new failure result
  def self.failure(error = nil)
    error_hash = case error
                 when ServiceError
                   {
                     message: error.message,
                     code: error.code,
                     details: error.details
                   }
                 when String
                   { message: error, code: :general_error }
                 when Hash
                   if error.key?(:error) # For backward compatibility
                     error[:error]
                   else
                     error
                   end
                 else
                   { message: "Unknown error", code: :unknown_error }
                 end

    new(false, nil, error_hash)
  end

  # Check if this result has a specific error code
  # @param code [Symbol] The error code to check for
  # @return [Boolean] True if the error code matches
  def error_code?(code)
    failure? && error.is_a?(Hash) && error[:code] == code
  end

  # Get the error message
  # @return [String] The error message or a default message
  def error_message
    return nil if success?

    if error.is_a?(Hash) && error[:message].present?
      error[:message]
    else
      "An error occurred"
    end
  end

  # Get the error code
  # @return [Symbol, nil] The error code or nil if not available
  def error_code
    return nil if success?

    if error.is_a?(Hash) && error[:code].present?
      error[:code]
    else
      :unknown_error
    end
  end

  # Get the error details
  # @return [Hash, nil] The error details or nil if not available
  def error_details
    return nil if success?

    if error.is_a?(Hash) && error[:details].present?
      error[:details]
    else
      nil
    end
  end

  # Create a new result with additional data
  # @param new_data [Hash] Additional data to merge with existing data
  # @return [Result] A new result with merged data
  def with_data(new_data)
    return self unless success?

    merged_data = if data.is_a?(Hash) && new_data.is_a?(Hash)
                    data.merge(new_data)
                  else
                    new_data
                  end

    Result.success(merged_data)
  end

  # Log the result to the Rails logger
  # @param logger_level [Symbol] The log level to use (:info, :error, etc.)
  # @return [Result] Self for chaining
  def log(logger_level = nil)
    level = if logger_level
              logger_level
            elsif success?
              :info
            else
              :error
            end

    if success?
      Rails.logger.send(level, "Result: Success - #{data.inspect}")
    else
      Rails.logger.send(level, "Result: Failure - #{error.inspect}")
    end

    self
  end

  # Map a success result to a new result using the provided block
  # @yield [data] Block that transforms the result data
  # @return [Result] A new result with the transformed data
  def map
    return self unless success?
    return self unless block_given?

    begin
      new_data = yield(data)
      Result.success(new_data)
    rescue => e
      Result.failure(ServiceError.new("Error mapping result: #{e.message}", :mapping_error, e))
    end
  end

  # Chain multiple operations that return Result objects
  # @yield [data] Block that returns a new Result object
  # @return [Result] The final Result after all operations
  def and_then
    return self unless success?
    return self unless block_given?

    begin
      yield(data)
    rescue => e
      Result.failure(ServiceError.new("Error in and_then chain: #{e.message}", :chain_error, e))
    end
  end
end

# Base class for service errors
class ServiceError < StandardError
  attr_reader :code, :details

  # @param message [String] The error message
  # @param code [Symbol] A symbol representing the error type
  # @param details [Object] Additional details about the error
  def initialize(message, code = :general_error, details = nil)
    super(message)
    @code = code
    @details = details
  end
end

# Error for validation failures
class ValidationError < ServiceError
  def initialize(message = "Validation failed", details = nil)
    super(message, :validation_error, details)
  end
end

# Error for authentication/authorization failures
class AuthenticationError < ServiceError
  def initialize(message = "Authentication failed", details = nil)
    super(message, :authentication_error, details)
  end
end

# Error for resource not found
class NotFoundError < ServiceError
  def initialize(message = "Resource not found", details = nil)
    super(message, :not_found, details)
  end
end

# Error for insufficient funds
class InsufficientFundsError < ServiceError
  def initialize(message = "Insufficient funds", details = nil)
    super(message, :insufficient_funds, details)
  end
end

# Error for business rule violations
class BusinessRuleError < ServiceError
  def initialize(message = "Business rule violation", code = :business_rule_error, details = nil)
    super(message, code, details)
  end
end

# Error for external service failures
class ExternalServiceError < ServiceError
  def initialize(message = "External service error", details = nil)
    super(message, :external_service_error, details)
  end
end

# Error for security violations
class SecurityViolationError < ServiceError
  def initialize(message = "Security violation", details = nil)
    super(message, :security_error, details)
  end
end

# Error for concurrency issues
class ConcurrencyError < ServiceError
  def initialize(message = "Concurrent modification detected", details = nil)
    super(message, :concurrency_error, details)
  end
end
