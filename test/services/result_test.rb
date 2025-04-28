require 'test_helper'

class ResultTest < ActiveSupport::TestCase
  test "Result.success creates a success result" do
    result = Result.success(data: "test data")
    assert result.success?
    assert_not result.failure?
    assert_equal "test data", result.data[:data]
  end

  test "Result.failure creates a failure result" do
    result = Result.failure(message: "test error", code: :test_error)
    assert result.failure?
    assert_not result.success?
    assert_equal "test error", result.error_message
    assert_equal :test_error, result.error_code
  end
  
  test "Result.failure with error: hash for backwards compatibility" do
    result = Result.failure(error: { message: "test error", code: :test_error })
    assert result.failure?
    assert_equal "test error", result.error_message
    assert_equal :test_error, result.error_code
  end

  test "Result.failure with ServiceError" do
    error = ServiceError.new("test service error", :service_error, { detail: "some detail" })
    result = Result.failure(error)
    assert result.failure?
    assert_equal "test service error", result.error_message
    assert_equal :service_error, result.error_code
    assert_equal({ detail: "some detail" }, result.error_details)
  end

  test "Result.failure with string" do
    result = Result.failure("simple error message")
    assert result.failure?
    assert_equal "simple error message", result.error_message
    assert_equal :general_error, result.error_code
  end

  test "Result#error_code? checks for specific error code" do
    result = Result.failure(code: :not_found, message: "Not found")
    assert result.error_code?(:not_found)
    assert_not result.error_code?(:validation_error)
  end

  test "Result#with_data merges new data with existing data" do
    result = Result.success(name: "Original")
    new_result = result.with_data(age: 30)
    
    assert new_result.success?
    assert_equal "Original", new_result.data[:name]
    assert_equal 30, new_result.data[:age]
  end

  test "Result#map transforms success data" do
    result = Result.success(count: 5)
    mapped_result = result.map { |data| { doubled: data[:count] * 2 } }
    
    assert mapped_result.success?
    assert_equal 10, mapped_result.data[:doubled]
  end

  test "Result#map doesn't transform failure" do
    result = Result.failure(message: "Error")
    mapped_result = result.map { |data| { transformed: true } }
    
    assert mapped_result.failure?
    assert_equal "Error", mapped_result.error_message
  end

  test "Result#and_then chains operations" do
    result = Result.success(value: 5)
    
    chained_result = result.and_then do |data|
      if data[:value] > 3
        Result.success(valid: true, value: data[:value])
      else
        Result.failure(message: "Value too low")
      end
    end
    
    assert chained_result.success?
    assert chained_result.data[:valid]
    assert_equal 5, chained_result.data[:value]
  end

  test "Result#and_then short-circuits on failure" do
    result = Result.failure(message: "Initial error")
    
    called = false
    chained_result = result.and_then do |data|
      called = true
      Result.success(processed: true)
    end
    
    assert_not called, "Block should not be called for failure results"
    assert chained_result.failure?
    assert_equal "Initial error", chained_result.error_message
  end

  test "ValidationError creates proper error codes" do
    error = ValidationError.new("Invalid data")
    result = Result.failure(error)
    
    assert_equal :validation_error, result.error_code
    assert_equal "Invalid data", result.error_message
  end

  test "AuthenticationError creates proper error codes" do
    error = AuthenticationError.new
    result = Result.failure(error)
    
    assert_equal :authentication_error, result.error_code
    assert_equal "Authentication failed", result.error_message
  end

  test "NotFoundError creates proper error codes" do
    error = NotFoundError.new("User not found")
    result = Result.failure(error)
    
    assert_equal :not_found, result.error_code
    assert_equal "User not found", result.error_message
  end

  test "InsufficientFundsError creates proper error codes" do
    error = InsufficientFundsError.new
    result = Result.failure(error)
    
    assert_equal :insufficient_funds, result.error_code
    assert_equal "Insufficient funds", result.error_message
  end
end
