module PaymentProcessors
  # Base class for all payment processors
  class BaseProcessor
    attr_reader :errors

    def initialize
      @errors = []
    end

    # Verify a deposit transaction
    # @param amount [Decimal] The amount being deposited
    # @param currency [String] The currency code
    # @param reference [String] External reference from payment provider
    # @param metadata [Hash] Additional transaction metadata
    # @param verification_data [Hash] Additional verification data
    # @return [Hash] Result of the verification
    def verify_deposit(amount:, currency:, reference:, metadata: {}, verification_data: {})
      raise NotImplementedError, "#{self.class.name} must implement #verify_deposit"
    end

    # Process a withdrawal transaction
    # @param amount [Decimal] The amount being withdrawn
    # @param currency [String] The currency code
    # @param destination [Hash] Destination account details
    # @param reference [String] Transaction reference
    # @param metadata [Hash] Additional transaction metadata
    # @param verification_data [Hash] Additional verification data
    # @return [Hash] Result of the withdrawal processing
    def process_withdrawal(amount:, currency:, destination:, reference:, metadata: {}, verification_data: {})
      raise NotImplementedError, "#{self.class.name} must implement #process_withdrawal"
    end

    # Process a payment transaction
    # @param amount [Decimal] The amount being paid
    # @param currency [String] The currency code
    # @param destination [Hash] Destination account details
    # @param reference [String] Transaction reference
    # @param metadata [Hash] Additional transaction metadata
    # @param verification_data [Hash] Additional verification data
    # @return [Hash] Result of the payment processing
    def process_payment(amount:, currency:, destination:, reference:, metadata: {}, verification_data: {})
      raise NotImplementedError, "#{self.class.name} must implement #process_payment"
    end

    protected

    # Log a processor operation
    # @param operation [String] The operation being performed
    # @param params [Hash] Parameters for the operation
    # @param result [Hash] Result of the operation
    def log_operation(operation, params, result)
      # Remove sensitive data from logs
      safe_params = params.deep_dup
      safe_params.delete(:verification_data)
      if safe_params[:destination].is_a?(Hash)
        safe_params[:destination] = safe_params[:destination].except(:account_number, :card_number)
      end

      Rails.logger.info("PAYMENT PROCESSOR [#{self.class.name}] #{operation}: #{safe_params.inspect} => #{result.inspect}")
    end

    # Format a standard success response
    # @param message [String] Success message
    # @param provider_reference [String] Reference from the payment provider
    # @param data [Hash] Additional data to include in the response
    # @return [Hash] Formatted success response
    def success_response(message, provider_reference = nil, data = {})
      response = {
        success: true,
        message: message,
        code: :success
      }
      response[:provider_reference] = provider_reference if provider_reference
      response.merge(data)
    end

    # Format a standard error response
    # @param message [String] Error message
    # @param code [Symbol] Error code
    # @param data [Hash] Additional data to include in the response
    # @return [Hash] Formatted error response
    def error_response(message, code = :processor_error, data = {})
      response = {
        success: false,
        message: message,
        code: code
      }
      response.merge(data)
    end
  end
end
