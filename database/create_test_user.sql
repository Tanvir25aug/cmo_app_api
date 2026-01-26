-- =============================================
-- Create Test User in AspNetUsers Table
-- =============================================
-- Password: Admin@123
-- Email: testuser@otbl.com
-- =============================================

USE MeterOCRDESCO;
GO

-- Delete existing test user if exists
DELETE FROM AspNetUsers WHERE Email = 'testuser@otbl.com';
GO

-- Create new test user
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
    NEWID(),                                                          -- Id
    'testuser',                                                       -- UserName
    'TESTUSER',                                                       -- NormalizedUserName
    'testuser@otbl.com',                                             -- Email
    'TESTUSER@OTBL.COM',                                             -- NormalizedEmail
    1,                                                                -- EmailConfirmed
    'AQAAAAEAACcQAAAAEJ7Qw8fZqVmYJ1c6vGp5xQGZxKp5YqKF1WJc5QGZxKp5YqKF1WJc5QGZxKp5YqKF1w==', -- PasswordHash for "Admin@123"
    CONVERT(NVARCHAR(MAX), NEWID()),                                 -- SecurityStamp
    CONVERT(NVARCHAR(MAX), NEWID()),                                 -- ConcurrencyStamp
    '01712345678',                                                    -- PhoneNumber
    1,                                                                -- PhoneNumberConfirmed
    0,                                                                -- TwoFactorEnabled
    NULL,                                                             -- LockoutEnd
    0,                                                                -- LockoutEnabled
    0,                                                                -- AccessFailedCount
    'Test',                                                           -- FirstName
    'User',                                                           -- LastName
    NULL,                                                             -- ProfilePicUrl
    GETDATE(),                                                        -- DateCreated
    NULL,                                                             -- LastLoginTime
    1,                                                                -- Activated
    NULL,                                                             -- RoleId
    NULL,                                                             -- UserId
    NULL                                                              -- MenuSecurityType
);
GO

-- Verify user was created
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

PRINT '';
PRINT '========================================';
PRINT 'Test User Created Successfully!';
PRINT '========================================';
PRINT '';
PRINT 'Login Credentials:';
PRINT '  Email:    testuser@otbl.com';
PRINT '  Password: Admin@123';
PRINT '';
PRINT 'User Details:';
PRINT '  Name:     Test User';
PRINT '  Phone:    01712345678';
PRINT '  Active:   Yes';
PRINT '';
GO
