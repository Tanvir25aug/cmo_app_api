-- =============================================
-- Insert Test User
-- =============================================
USE MeterOCRDESCO;
GO

-- Default password: "admin123" (hashed with bcrypt)
-- You can change this after first login

DECLARE @userId CHAR(36) = NEWID();

IF NOT EXISTS (SELECT 1 FROM users WHERE email = 'admin@otbl.com')
BEGIN
    INSERT INTO users (
        id,
        username,
        email,
        password,
        full_name,
        phone,
        role,
        is_active,
        created_at,
        updated_at
    )
    VALUES (
        @userId,
        'admin',
        'admin@otbl.com',
        '$2a$10$YourBcryptHashHere', -- This will be replaced after first register
        'System Administrator',
        '01712345678',
        'admin',
        1,
        SYSDATETIMEOFFSET(),
        SYSDATETIMEOFFSET()
    );

    PRINT 'Test admin user created:';
    PRINT '  Email: admin@otbl.com';
    PRINT '  Password: admin123 (you must register first to hash password)';
END
ELSE
BEGIN
    PRINT 'User already exists: admin@otbl.com';
END
GO
