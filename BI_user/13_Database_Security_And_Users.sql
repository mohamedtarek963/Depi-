/*
===============================================================================
Project: OULAD Data Warehouse
Script: 13_Database_Security_And_Users
Description: 
    - Creates a dedicated SQL Server Login and Database User for reporting.
    - Restricts access (DENY) to the core Medallion schemas (Bronze, Silver, Gold).
    - Grants read access (GRANT SELECT) strictly to the specific dbo reporting views.

BY\ Abdelrahman Ahmed
===============================================================================
*/

USE oulad_warehouse;
GO

-------------------------------------------------------------------------------
-- STEP 1: Create Server Login
-- This is the login used to connect to the SQL Server instance (Power BI will use this).
-------------------------------------------------------------------------------
USE master;
GO
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'BI_User')
BEGIN
    CREATE LOGIN BI_User WITH PASSWORD = '123456', CHECK_POLICY = OFF;
END
GO

-- Set the default database so the login lands on oulad_warehouse automatically.
-- Placed outside the IF block so it always applies, even on re-runs.
ALTER LOGIN BI_User WITH DEFAULT_DATABASE = oulad_warehouse;
GO

-------------------------------------------------------------------------------
-- STEP 2: Create Database User (linked to the Login)
-- Dropping and recreating ensures the User's SID always matches the Login's SID.
-- This avoids the "orphaned user" issue that causes false permission-denied errors.
-------------------------------------------------------------------------------
USE oulad_warehouse;
GO
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'BI_User')
BEGIN
    DROP USER BI_User;
END
GO
CREATE USER BI_User FOR LOGIN BI_User;
GO

-------------------------------------------------------------------------------
-- STEP 3: Deny access to Medallion layer schemas (Bronze, Silver, Gold)
-- This hides the raw/staging data completely from the BI user.
-------------------------------------------------------------------------------
DENY SELECT ON SCHEMA::Bronze TO BI_User;
DENY SELECT ON SCHEMA::Silver TO BI_User;
DENY SELECT ON SCHEMA::Gold   TO BI_User;
GO

-------------------------------------------------------------------------------
-- STEP 4: Grant SELECT on the clean reporting views (dbo schema) only
-- These are the only objects Power BI / Excel should ever touch.
-------------------------------------------------------------------------------
GRANT SELECT ON OBJECT::dbo.Dim_Modules_Catalog     TO BI_User;
GRANT SELECT ON OBJECT::dbo.Dim_Students_Profile    TO BI_User;
GRANT SELECT ON OBJECT::dbo.Dim_Assessments_Info    TO BI_User;
GRANT SELECT ON OBJECT::dbo.Dim_Vle_Resources       TO BI_User;
GRANT SELECT ON OBJECT::dbo.Fact_Enrollment         TO BI_User;
GRANT SELECT ON OBJECT::dbo.Fact_Student_Scores     TO BI_User;
GRANT SELECT ON OBJECT::dbo.Fact_Student_Vle_Clicks TO BI_User;
GRANT CREATE TABLE TO BI_User;
GO

-------------------------------------------------------------------------------
-- STEP 5: Grant VIEW DEFINITION on the same views
-- Needed so tools like Power BI can read the view's metadata/columns, not just the data.
-------------------------------------------------------------------------------
GRANT VIEW DEFINITION ON OBJECT::dbo.Dim_Modules_Catalog     TO BI_User;
GRANT VIEW DEFINITION ON OBJECT::dbo.Dim_Students_Profile    TO BI_User;
GRANT VIEW DEFINITION ON OBJECT::dbo.Dim_Assessments_Info    TO BI_User;
GRANT VIEW DEFINITION ON OBJECT::dbo.Dim_Vle_Resources       TO BI_User;
GRANT VIEW DEFINITION ON OBJECT::dbo.Fact_Enrollment         TO BI_User;
GRANT VIEW DEFINITION ON OBJECT::dbo.Fact_Student_Scores     TO BI_User;
GRANT VIEW DEFINITION ON OBJECT::dbo.Fact_Student_Vle_Clicks TO BI_User;
GRANT ALTER, INSERT, UPDATE, DELETE ON SCHEMA::Reporting TO BI_User;
GO

-------------------------------------------------------------------------------
-- STEP 6: Grant CONNECT permission on the database
-- Required so the login can actually open a connection to this database.
-------------------------------------------------------------------------------
GRANT CONNECT ON DATABASE::oulad_warehouse TO BI_User;
GO

PRINT 'Security Setup Completed. BI_User restricted to Reporting Views only.';