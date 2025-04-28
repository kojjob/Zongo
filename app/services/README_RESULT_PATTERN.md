# Result Object Pattern for Error Handling

This document describes the standardized Result object pattern implemented in our application for consistent error handling across services.

## Overview

The Result pattern provides a consistent way to handle success and failure outcomes from operations, especially in service objects. It helps avoid exceptions for control flow and provides a clear, structured way to pass errors and success data.

## Basic Usage

### Creating Results

```ruby
# Create a success result with data
result = Result.success({ user: user })

# Create a failure result with error information
result = Result.failure({ message: "Invalid input", code: :validation_error })

# Create a failure result from an exception
begin
  # Some operation that might raise an exception
rescue => e
  result = Result.failure(ServiceError.new("Operation failed", :system_error, e))
end
```

### Checking Results

```ruby
if result.success?
  # Handle success case
  user = result.data[:user]
else
  # Handle failure case
  message = result.error_message
  code = result.error_code
  flash[:alert] = message
end
```

### Using in Service Objects

```ruby
class UserService
  def create_user(params)
    user = User.new(params)
    
    # Validate the user
    unless user.valid?
      return Result.failure({
        message: "Invalid user data",
        code: :validation_error,
        details: user.errors.full_messages
      })
    end
    
    # Save the user
    if user.save
      Result.success({ user: user })
    else
      Result.failure({
        message: "Failed to create user",
        code: :creation_failed,
        details: user.errors.full_messages
      })
    end
  end
end
```

### Using in Controllers with ResultHandler

The `ResultHandler` concern provides helpers for handling Result objects in controllers:

```ruby
class UsersController < ApplicationController
  include ResultHandler
  
  def create
    result = UserService.new.create_user(user_params)
    
    handle_result(result, {
      success_message: "User created successfully",
      success_redirect: users_path,
      failure_action: :render,
      render_options: { action: :new }
    }) do |data|
      # Optional block for additional success handling
      session[:new_user_id] = data[:user].id
    end
  end
end
```

## Error Types

The pattern includes predefined error types:

- `ServiceError`: Base class for service errors
- `ValidationError`: For validation failures
- `AuthenticationError`: For authentication/authorization failures
- `NotFoundError`: For resource not found errors
- `InsufficientFundsError`: For insufficient funds errors (specific to financial operations)
- `BusinessRuleError`: For business rule violations
- `ExternalServiceError`: For external service failures
- `SecurityError`: For security violations
- `ConcurrencyError`: For concurrency issues

## Advanced Features

### Chaining Operations

```ruby
result = UserService.new.create_user(params)
  .and_then { |data| EmailService.new.send_welcome_email(data[:user]) }
  .and_then { |data| NotificationService.new.notify_admin_of_new_user(data[:user]) }

if result.success?
  # All operations succeeded
else
  # One of the operations failed
end
```

### Mapping Results

```ruby
result = UserService.new.find_user(id)
  .map { |data| { user_json: data[:user].as_json } }

# Result now contains the transformed data if successful
```

### Logging Results

```ruby
result = UserService.new.create_user(params).log
# Logs success or failure information at appropriate log level
```

## Best Practices

1. Always return Result objects from service methods
2. Keep result data structure consistent within a service
3. Include meaningful error codes and messages
4. Use appropriate predefined error types
5. Avoid using exceptions for control flow
6. Use the ResultHandler concern in controllers for consistent handling
7. Keep error messages user-friendly if they'll be displayed to users
8. Include detailed error information for logging and debugging

## Example Implementation

See the `app/services/result.rb` file for the full implementation of the Result pattern.

## Controller Integration

See the `app/controllers/concerns/result_handler.rb` file for integration with controllers.
