# Password Reset via Console

This guide explains how to reset a user's password in development using the Rails console or command line.

## Method 1: Using the Command Line Script

The simplest way to reset a password is to use the provided script:

```bash
./bin/reset_password user@example.com
```

This will:
1. Generate a password reset token for the user
2. Display the reset link in the terminal
3. Copy the link to your clipboard (if possible)

You can then paste the link into your browser to reset the password.

## Method 2: Using the Rails Console

If you prefer to use the Rails console:

```ruby
# Start the console
rails console

# Find the user
user = User.find_by(email: 'user@example.com')

# Generate a reset token
raw_token, hashed_token = Devise.token_generator.generate(User, :reset_password_token)
user.reset_password_token = hashed_token
user.reset_password_sent_at = Time.now.utc
user.save(validate: false)

# Generate the reset URL
host = Rails.application.config.action_mailer.default_url_options[:host] || 'localhost'
port = Rails.application.config.action_mailer.default_url_options[:port] || 3000
reset_url = "http://#{host}:#{port}/users/password/edit?reset_password_token=#{raw_token}"

# Print the URL
puts reset_url
```

## Method 3: Using cURL

You can also use cURL to get a reset link:

```bash
curl "http://localhost:3000/dev/console_reset/user@example.com"
```

This will return a JSON response with the reset link.

## Notes

- These methods are for development only and should not be used in production.
- The reset link will expire after the time specified in your Devise configuration (usually 6 hours).
- After clicking the link, the user will be redirected to the password reset form where they can enter a new password.
