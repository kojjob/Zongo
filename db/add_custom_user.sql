-- This SQL script adds a custom admin user if it doesn't exist
-- SQL Server compatible version

-- Check if user exists and create if not
IF NOT EXISTS (SELECT 1 FROM users WHERE email = 'admin@example.com')
BEGIN
    -- Insert user
    DECLARE @user_id INT;

    INSERT INTO users (
        email,
        encrypted_password,
        username,
        phone,
        status,
        kyc_level,
        admin,
        confirmed_at,
        created_at,
        updated_at
    ) VALUES (
        'admin@example.com',
        -- This is the encrypted form of 'password123'
        '$2a$12$K8GpVT0qOKpZYXzwCYd.5.4P1Z0oH8YsILZ/TiGhkYgcI5Zx4hVDe',
        'admin',
        '+233501234599',
        0, -- active status (0 is active in the enum)
        1, -- verified kyc_level (1 is verified in the enum)
        1, -- admin (using 1 instead of TRUE for SQL Server)
        GETDATE(), -- confirmed_at (needed for login)
        GETDATE(),
        GETDATE()
    );

    -- Get the inserted user ID
    SET @user_id = SCOPE_IDENTITY();

    -- Insert wallet
    INSERT INTO wallets (
        user_id,
        wallet_id,
        status,
        balance,
        currency,
        daily_limit,
        created_at,
        updated_at
    ) VALUES (
        @user_id,
        'W' + UPPER(SUBSTRING(CONVERT(VARCHAR(36), NEWID()), 1, 12)),
        0, -- active status
        5000.00,
        'GHS',
        2000.00,
        GETDATE(),
        GETDATE()
    );

    -- Insert payment method
    INSERT INTO payment_methods (
        user_id,
        method_type,
        provider,
        account_number_digest,
        masked_number,
        account_name,
        phone_number, -- Added missing field
        description,
        [default], -- Using square brackets for reserved keyword
        status,
        verification_status,
        last_used_at,
        created_at,
        updated_at
    ) VALUES (
        @user_id,
        0, -- mobile_money
        'MTN Mobile Money',
        '$2a$12$K8GpVT0qOKpZYXzwCYd.5.4P1Z0oH8YsILZ/TiGhkYgcI5Zx4hVDe',
        'xxxx1234',
        'Admin User',
        '+233501234599', -- Same as user phone
        'MTN Mobile Money Account',
        1, -- default (using 1 instead of TRUE)
        0, -- active status
        1, -- verified verification_status
        GETDATE(),
        GETDATE(),
        GETDATE()
    );

    PRINT 'Created user: admin@example.com with password: password123';
END
ELSE
BEGIN
    PRINT 'User admin@example.com already exists';
END
