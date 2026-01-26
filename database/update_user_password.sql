-- =============================================
-- Update User Password for Testing
-- =============================================
-- This script updates a user's password to a known value
-- Password will be hashed by the API on next login attempt

USE MeterOCRDESCO;
GO

-- Show existing users (without passwords)
PRINT '========================================';
PRINT 'Existing Users:';
PRINT '========================================';
SELECT
    id,
    username,
    email,
    full_name,
    role,
    is_active
FROM users;
GO

-- =============================================
-- Option 1: Set a bcrypt hashed password manually
-- =============================================
-- Password: "admin123" (bcrypt hash)
-- Run this to set a known password for testing

DECLARE @testEmail NVARCHAR(100) = 'admin@otbl.com'; -- Change this to your user's email
DECLARE @hashedPassword NVARCHAR(255) = '$2a$10$YourHashedPasswordHere'; -- You need a real bcrypt hash

-- NOTE: You cannot use this directly - SQL Server doesn't have bcrypt
-- Instead, you should register a new user via the API or use the test registration below

PRINT '';
PRINT '========================================';
PRINT 'IMPORTANT: Password must be bcrypt hashed';
PRINT '========================================';
PRINT 'You have 2 options:';
PRINT '';
PRINT 'Option 1: Register a new test user via API';
PRINT '  POST /api/auth/register';
PRINT '  Body: { "username": "testuser", "email": "test@example.com", "password": "password123" }';
PRINT '';
PRINT 'Option 2: Use the test registration script below';
PRINT '';
GO
