-- =============================================
-- Create Test User by Copying Password from Existing User
-- This ensures the password hash format is correct
-- =============================================

USE MeterOCRDESCO;
GO

-- STEP 1: Check existing users
PRINT '========================================';
PRINT 'Existing Users:';
PRINT '========================================';
SELECT
    UserName,
    Email,
    FirstName,
    LastName,
    Activated
FROM AspNetUsers;
GO

PRINT '';
PRINT '----------------------------------------';
PRINT 'Copy password from which user?';
PRINT 'Update the script with the email below:';
PRINT '----------------------------------------';
PRINT '';

-- STEP 2: Create new user with copied password
-- CHANGE THIS: Update with your existing user's email
DECLARE @SourceEmail NVARCHAR(256) = 'abid.oculin2022@gmail.com'; -- <-- CHANGE THIS to your existing user
DECLARE @PasswordHash NVARCHAR(MAX);

-- Get password hash from existing user
SELECT @PasswordHash = PasswordHash
FROM AspNetUsers
WHERE Email = @SourceEmail;

IF @PasswordHash IS NULL
BEGIN
    PRINT '❌ Source user not found!';
    PRINT 'Please update @SourceEmail with a valid user email.';
END
ELSE
BEGIN
    -- Check if test user already exists
    IF EXISTS (SELECT 1 FROM AspNetUsers WHERE Email = 'testuser@otbl.com')
    BEGIN
        PRINT '⚠️  User testuser@otbl.com already exists.';
        PRINT '';
        PRINT 'To recreate, first delete it:';
        PRINT 'DELETE FROM AspNetUsers WHERE Email = ''testuser@otbl.com'';';
    END
    ELSE
    BEGIN
        -- Create test user with same password as source user
        DECLARE @NewUserId NVARCHAR(450) = NEWID();

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
            @NewUserId,
            'testuser',
            'TESTUSER',
            'testuser@otbl.com',
            'TESTUSER@OTBL.COM',
            1,
            @PasswordHash,                    -- Same password as source user!
            CONVERT(NVARCHAR(MAX), NEWID()),
            CONVERT(NVARCHAR(MAX), NEWID()),
            '01712345678',
            1,
            0,
            NULL,
            0,
            0,
            'Test',
            'User',
            NULL,
            GETDATE(),
            NULL,
            1,
            NULL,
            NULL,
            NULL
        );

        PRINT '';
        PRINT '========================================';
        PRINT '✅ Test User Created Successfully!';
        PRINT '========================================';
        PRINT '';
        PRINT 'Login Credentials:';
        PRINT '  Email:    testuser@otbl.com';
        PRINT '  Password: [SAME as ' + @SourceEmail + ']';
        PRINT '';
        PRINT 'User Details:';
        PRINT '  Name:     Test User';
        PRINT '  Phone:    01712345678';
        PRINT '  Active:   Yes';
        PRINT '';
        PRINT 'The password is identical to the source user.';
        PRINT '';
    END
END
GO

-- Show created user
SELECT
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
