-- =============================================
-- QUICK: Create Test User
-- Copy and paste this entire script into SQL Server Management Studio
-- =============================================

USE MeterOCRDESCO;
GO

-- Create test user by copying password from existing user
DECLARE @PasswordHash NVARCHAR(MAX);
DECLARE @NewUserId NVARCHAR(450) = NEWID();

-- Get password from existing user
SELECT TOP 1 @PasswordHash = PasswordHash
FROM AspNetUsers
WHERE Email = 'abid.oculin2022@gmail.com';

-- Insert test user
INSERT INTO AspNetUsers (
    Id, UserName, NormalizedUserName, Email, NormalizedEmail,
    EmailConfirmed, PasswordHash, SecurityStamp, ConcurrencyStamp,
    PhoneNumber, PhoneNumberConfirmed, TwoFactorEnabled,
    LockoutEnabled, AccessFailedCount, FirstName, LastName,
    DateCreated, Activated
)
VALUES (
    @NewUserId,
    'testuser',
    'TESTUSER',
    'testuser@otbl.com',
    'TESTUSER@OTBL.COM',
    1,
    @PasswordHash,
    CONVERT(NVARCHAR(MAX), NEWID()),
    CONVERT(NVARCHAR(MAX), NEWID()),
    '01712345678',
    1,
    0,
    0,
    0,
    'Test',
    'User',
    GETDATE(),
    1
);

-- Show result
SELECT
    UserName,
    Email,
    FirstName,
    LastName,
    Activated
FROM AspNetUsers
WHERE Email = 'testuser@otbl.com';

PRINT '✅ Test user created!';
PRINT 'Email: testuser@otbl.com';
PRINT 'Password: Abid@123 (same as abid.oculin2022@gmail.com)';
GO
