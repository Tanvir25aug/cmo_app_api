-- =============================================
-- CMO API - Database Schema Creation Script
-- Database: MeterOCRDESCO
-- =============================================

USE MeterOCRDESCO;
GO

-- =============================================
-- Drop tables if they exist (optional - for clean install)
-- =============================================
-- IF OBJECT_ID('cmo_requests', 'U') IS NOT NULL DROP TABLE cmo_requests;
-- IF OBJECT_ID('users', 'U') IS NOT NULL DROP TABLE users;
-- GO

-- =============================================
-- Create Users Table
-- =============================================
IF OBJECT_ID('users', 'U') IS NULL
BEGIN
    CREATE TABLE users (
        id CHAR(36) PRIMARY KEY,
        username NVARCHAR(50) NOT NULL UNIQUE,
        email NVARCHAR(100) NOT NULL UNIQUE,
        password NVARCHAR(255) NOT NULL,
        full_name NVARCHAR(100) NULL,
        phone NVARCHAR(20) NULL,
        role NVARCHAR(20) DEFAULT 'user',
        profile_image NVARCHAR(255) NULL,
        is_active BIT DEFAULT 1,
        last_login DATETIMEOFFSET NULL,
        created_at DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET(),
        updated_at DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET()
    );

    PRINT 'Table [users] created successfully';
END
ELSE
BEGIN
    PRINT 'Table [users] already exists';
END
GO

-- =============================================
-- Create CMO Requests Table
-- =============================================
IF OBJECT_ID('cmo_requests', 'U') IS NULL
BEGIN
    CREATE TABLE cmo_requests (
        id CHAR(36) PRIMARY KEY,

        -- Customer Information
        customer_id NVARCHAR(50) NULL,
        new_meter_id NVARCHAR(50) NULL,
        customer_name NVARCHAR(100) NOT NULL,
        flat_no NVARCHAR(20) NULL,
        floor NVARCHAR(20) NULL,
        mobile_number NVARCHAR(20) NOT NULL,
        secondary_mobile_number NVARCHAR(20) NULL,
        email NVARCHAR(100) NULL,
        nid NVARCHAR(20) NULL,
        nocs NVARCHAR(50) NULL,

        -- Meter Details
        feeder NVARCHAR(50) NULL,
        bill_group NVARCHAR(50) NULL,
        sanction_load NVARCHAR(20) NULL,
        book_number NVARCHAR(50) NULL,
        tariff NVARCHAR(50) NULL,

        -- Old Meter Information
        old_meter_type NVARCHAR(10) NULL CHECK (old_meter_type IN ('1P', '3P')),
        old_meter_number NVARCHAR(50) NULL,
        old_meter_image_path NVARCHAR(255) NULL,
        old_meter_reading NVARCHAR(20) NULL,
        on_peak NVARCHAR(20) NULL,
        off_peak NVARCHAR(20) NULL,
        kvar NVARCHAR(20) NULL,

        -- Installation Information
        install_date DATE NULL,

        -- Seal Information
        battery_cover_seal NVARCHAR(50) NULL,
        battery_cover_seal_image_path NVARCHAR(255) NULL,
        terminal_seal_1 NVARCHAR(50) NULL,
        terminal_seal_2 NVARCHAR(50) NULL,
        terminal_cover_seal_image_path NVARCHAR(255) NULL,

        -- Additional Information
        has_steel_box BIT DEFAULT 0,
        install_by NVARCHAR(100) NULL,

        -- Status & Sync
        status NVARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'pending', 'uploaded', 'approved', 'rejected')),
        is_synced BIT DEFAULT 0,
        synced_at DATETIMEOFFSET NULL,

        -- User Reference
        user_id CHAR(36) NOT NULL,

        -- Timestamps
        created_at DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET(),
        updated_at DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET(),

        -- Foreign Key
        CONSTRAINT FK_cmo_requests_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    PRINT 'Table [cmo_requests] created successfully';

    -- Create indexes for better performance
    CREATE INDEX IDX_cmo_requests_user_id ON cmo_requests(user_id);
    CREATE INDEX IDX_cmo_requests_status ON cmo_requests(status);
    CREATE INDEX IDX_cmo_requests_customer_id ON cmo_requests(customer_id);
    CREATE INDEX IDX_cmo_requests_mobile_number ON cmo_requests(mobile_number);
    CREATE INDEX IDX_cmo_requests_created_at ON cmo_requests(created_at DESC);

    PRINT 'Indexes created successfully';
END
ELSE
BEGIN
    PRINT 'Table [cmo_requests] already exists';
END
GO

-- =============================================
-- Grant Permissions to rdpdc user
-- =============================================
GRANT SELECT, INSERT, UPDATE, DELETE ON users TO rdpdc;
GRANT SELECT, INSERT, UPDATE, DELETE ON cmo_requests TO rdpdc;
GO

PRINT '';
PRINT '========================================';
PRINT 'Database schema created successfully!';
PRINT '========================================';
PRINT '';
PRINT 'Tables created:';
PRINT '  - users';
PRINT '  - cmo_requests';
PRINT '';
PRINT 'Permissions granted to: rdpdc';
PRINT '';
GO
