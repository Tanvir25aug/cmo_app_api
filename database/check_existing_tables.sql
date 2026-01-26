-- =============================================
-- Check Existing Table Structures
-- =============================================
USE MeterOCRDESCO;
GO

-- Check if users table exists and show its structure
IF OBJECT_ID('users', 'U') IS NOT NULL
BEGIN
    PRINT '========================================';
    PRINT 'USERS TABLE STRUCTURE:';
    PRINT '========================================';

    SELECT
        COLUMN_NAME,
        DATA_TYPE,
        CHARACTER_MAXIMUM_LENGTH,
        IS_NULLABLE,
        COLUMN_DEFAULT
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'users'
    ORDER BY ORDINAL_POSITION;

    PRINT '';
    PRINT 'Indexes on users table:';
    SELECT
        i.name AS IndexName,
        COL_NAME(ic.object_id, ic.column_id) AS ColumnName,
        i.is_unique,
        i.is_primary_key
    FROM sys.indexes i
    INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
    WHERE i.object_id = OBJECT_ID('users');
END
ELSE
BEGIN
    PRINT '❌ users table does not exist';
END
GO

-- Check if cmo_requests table exists
IF OBJECT_ID('cmo_requests', 'U') IS NOT NULL
BEGIN
    PRINT '';
    PRINT '========================================';
    PRINT 'CMO_REQUESTS TABLE EXISTS';
    PRINT '========================================';

    SELECT
        COLUMN_NAME,
        DATA_TYPE,
        CHARACTER_MAXIMUM_LENGTH,
        IS_NULLABLE
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'cmo_requests'
    ORDER BY ORDINAL_POSITION;
END
ELSE
BEGIN
    PRINT '❌ cmo_requests table does not exist';
END
GO

-- Show sample user data (without password)
IF OBJECT_ID('users', 'U') IS NOT NULL
BEGIN
    PRINT '';
    PRINT '========================================';
    PRINT 'SAMPLE USER DATA:';
    PRINT '========================================';

    SELECT TOP 3
        id,
        username,
        email,
        full_name,
        phone,
        role,
        is_active,
        created_at
    FROM users;
END
GO
