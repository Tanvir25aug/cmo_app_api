-- =============================================
-- Create Test User for Login Testing
-- Run this in SQL Server Management Studio
-- =============================================

USE MeterOCRDESCO;
GO

-- Check if user already exists
IF EXISTS (SELECT 1 FROM AspNetUsers WHERE Email = 'testuser@otbl.com')
BEGIN
    PRINT 'User testuser@otbl.com already exists. Skipping insert.';
    PRINT '';
    PRINT 'If you want to recreate this user, first delete it:';
    PRINT 'DELETE FROM AspNetUsers WHERE Email = ''testuser@otbl.com'';';
    PRINT '';
END
ELSE
BEGIN
    -- Insert new test user
    DECLARE @UserId NVARCHAR(450) = NEWID();

    INSERT INTO AspNetUsers (
        Id,
        UserName,
        NormalizedUserName,
        Email,
        NormalizedEmail,
        EmailConfirmed,
        PasswordHash,
        SecurityStamp,
        ConcurrencyStamp,
        PhoneNumber,
        PhoneNumberConfirmed,
        TwoFactorEnabled,
        LockoutEnd,
        LockoutEnabled,
        AccessFailedCount,
        FirstName,
        LastName,
        ProfilePicUrl,
        DateCreated,
        LastLoginTime,
        Activated,
        RoleId,
        UserId,
        MenuSecurityType
    )
    VALUES (
        @UserId,                                                      -- Id
        'testuser',                                                   -- UserName
        'TESTUSER',                                                   -- NormalizedUserName
        'testuser@otbl.com',                                         -- Email
        'TESTUSER@OTBL.COM',                                         -- NormalizedEmail
        1,                                                            -- EmailConfirmed
        '$2a$10$YourHashWillBeReplacedByAPI',                        -- PasswordHash (temporary)
        CONVERT(NVARCHAR(MAX), NEWID()),                             -- SecurityStamp
        CONVERT(NVARCHAR(MAX), NEWID()),                             -- ConcurrencyStamp
        '01712345678',                                                -- PhoneNumber
        1,                                                            -- PhoneNumberConfirmed
        0,                                                            -- TwoFactorEnabled
        NULL,                                                         -- LockoutEnd
        0,                                                            -- LockoutEnabled
        0,                                                            -- AccessFailedCount
        'Test',                                                       -- FirstName
        'User',                                                       -- LastName
        NULL,                                                         -- ProfilePicUrl
        GETDATE(),                                                    -- DateCreated
        NULL,                                                         -- LastLoginTime
        1,                                                            -- Activated
        NULL,                                                         -- RoleId
        NULL,                                                         -- UserId
        NULL                                                          -- MenuSecurityType
    );

    PRINT '';
    PRINT '========================================';
    PRINT 'Test User Created Successfully!';
    PRINT '========================================';
    PRINT '';
    PRINT 'Login Credentials:';
    PRINT '  Email:    testuser@otbl.com';
    PRINT '  Password: [Use existing user password]';
    PRINT '';
    PRINT 'IMPORTANT:';
    PRINT '  The password hash is temporary.';
    PRINT '  Please use an EXISTING user''s credentials';
    PRINT '  OR copy password hash from an existing user.';
    PRINT '';
END
GO

-- Show the created user
SELECT
    Id,
    UserName,
    Email,
    FirstName,
    LastName,
    PhoneNumber,
    Activated,
    DateCreated
FROM AspNetUsers
WHERE Email = 'testuser@otbl.com';
GO
