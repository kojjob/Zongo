class AddCustomUser < ActiveRecord::Migration[8.0]
  def up
    # This migration should run after AddDescriptionToPaymentMethods
    # to ensure the description column exists

    # Create the user directly with SQL to avoid model validations
    # that might fail during migrations
    execute <<-SQL
      INSERT INTO users (
        email, encrypted_password, username, phone, status, kyc_level, admin,
        created_at, updated_at
      )
      VALUES (
        'kojcoder@gmail.com',
        '$2a$12$K8GpVT0qOKpZYXzwCYd.5.4P1Z0oH8YsILZ/TiGhkYgcI5Zx4hVDe', -- password123
        'kojcoder',
        '+233501234599',
        1, -- active status
        2, -- verified kyc_level
        TRUE, -- admin
        NOW(),
        NOW()
      )
      ON CONFLICT (email) DO NOTHING;
    SQL

    # Get the user ID
    user_id = execute("SELECT id FROM users WHERE email = 'kojcoder@gmail.com'").first['id']

    # Create a wallet for the user
    wallet_id = "W#{SecureRandom.alphanumeric(12).upcase}"
    execute <<-SQL
      INSERT INTO wallets (
        user_id, wallet_id, status, balance, currency, daily_limit,
        created_at, updated_at
      )
      VALUES (
        #{user_id},
        '#{wallet_id}',
        0, -- active status
        5000.00,
        'GHS',
        2000.00,
        NOW(),
        NOW()
      )
      ON CONFLICT (wallet_id) DO NOTHING;
    SQL

    # Check if the description column exists
    description_exists = column_exists?(:payment_methods, :description)

    # Create a payment method for the user
    if description_exists
      execute <<-SQL
        INSERT INTO payment_methods (
          user_id, method_type, provider, account_number_digest,
          masked_number, account_name, description, "default",
          status, verification_status, last_used_at,
          created_at, updated_at
        )
        VALUES (
          #{user_id},
          0, -- mobile_money
          'MTN Mobile Money',
          '$2a$12$K8GpVT0qOKpZYXzwCYd.5.4P1Z0oH8YsILZ/TiGhkYgcI5Zx4hVDe', -- encrypted 123456789
          'xxxx1234',
          'Kojo Coder',
          'MTN Mobile Money Account',
          TRUE,
          1, -- verified status
          1, -- verified verification_status
          NOW(),
          NOW(),
          NOW()
        );
      SQL
    else
      # If description column doesn't exist, insert without it
      execute <<-SQL
        INSERT INTO payment_methods (
          user_id, method_type, provider, account_number_digest,
          masked_number, account_name, "default",
          status, verification_status, last_used_at,
          created_at, updated_at
        )
        VALUES (
          #{user_id},
          0, -- mobile_money
          'MTN Mobile Money',
          '$2a$12$K8GpVT0qOKpZYXzwCYd.5.4P1Z0oH8YsILZ/TiGhkYgcI5Zx4hVDe', -- encrypted 123456789
          'xxxx1234',
          'Kojo Coder',
          TRUE,
          1, -- verified status
          1, -- verified verification_status
          NOW(),
          NOW(),
          NOW()
        );
      SQL
    end

    puts "Created user: kojcoder@gmail.com with password: password123"
  end

  def down
    execute("DELETE FROM payment_methods WHERE user_id IN (SELECT id FROM users WHERE email = 'kojcoder@gmail.com')")
    execute("DELETE FROM wallets WHERE user_id IN (SELECT id FROM users WHERE email = 'kojcoder@gmail.com')")
    execute("DELETE FROM users WHERE email = 'kojcoder@gmail.com'")
  end
end
