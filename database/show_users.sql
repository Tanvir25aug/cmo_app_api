-- =============================================
-- Show All Users with Login Info
-- =============================================

USE MeterOCRDESCO;
GO

SELECT
    UserName,
    Email,
    FirstName,
    LastName,
    PhoneNumber,
    Activated,
    DateCreated
FROM AspNetUsers
ORDER BY DateCreated DESC;
GO
