/*
===============================================================================
Project: OULAD Data Warehouse
Script: 12_Create_Reporting_Views
Description: 
    - Creates secure views inside the default 'dbo' schema.
    - These views abstract the underlying 'Gold' layer tables.
    - Power BI and Excel will connect through these views, showing clean table 
      names without the schema prefix.

BY\ Abdelrahman Ahmed
===============================================================================
*/

USE oulad_warehouse;
GO

-- 1. View for Dim_Modules_Catalog
DROP VIEW IF EXISTS dbo.Dim_Modules_Catalog;
GO
CREATE VIEW dbo.Dim_Modules_Catalog AS
SELECT 
    Module_Key,
    module_presentation_length,
    semester
FROM Gold.Dim_Modules_Catalog;
GO

-- 2. View for Dim_Students_Profile
DROP VIEW IF EXISTS dbo.Dim_Students_Profile;
GO
CREATE VIEW dbo.Dim_Students_Profile AS
SELECT 
    Student_Key,
    Module_Key,
    gender,
    region,
    highest_education,
    imd_band,
    age_band,
    num_of_prev_attempts,
    studied_credits,
    disability
FROM Gold.Dim_Students_Profile;
GO

-- 3. View for Dim_Assessments_Info
DROP VIEW IF EXISTS dbo.Dim_Assessments_Info;
GO
CREATE VIEW dbo.Dim_Assessments_Info AS
SELECT 
    id_assessment,
    Module_Key,
    assessment_type,
    [date],
    [weight],
    is_final_exam
FROM Gold.Dim_Assessments_Info;
GO

-- 4. View for Dim_Vle_Resources
DROP VIEW IF EXISTS dbo.Dim_Vle_Resources;
GO
CREATE VIEW dbo.Dim_Vle_Resources AS
SELECT 
    id_site,
    Module_Key,
    activity_type,
    week_from,
    week_to
FROM Gold.Dim_Vle_Resources;
GO

-- 5. View for Fact_Enrollment
DROP VIEW IF EXISTS dbo.Fact_Enrollment;
GO
CREATE VIEW dbo.Fact_Enrollment AS
SELECT 
    Student_Key,
    Module_Key,
    date_registration,
    date_unregistration,
    is_active,
    days_enrolled,
    final_result
FROM Gold.Fact_Enrollment;
GO

-- 6. View for Fact_Student_Scores
DROP VIEW IF EXISTS dbo.Fact_Student_Scores;
GO
CREATE VIEW dbo.Fact_Student_Scores AS
SELECT 
    Student_Key,
    id_assessment,
    date_submitted,
    score,
    weighted_score,
    is_late_submission
FROM Gold.Fact_Student_Scores;
GO

-- 7. View for Fact_Student_Vle_Clicks
DROP VIEW IF EXISTS dbo.Fact_Student_Vle_Clicks;
GO
CREATE VIEW dbo.Fact_Student_Vle_Clicks AS
SELECT 
    Student_Key,
    id_site,
    [date],
    sum_click
FROM Gold.Fact_Student_Vle_Clicks;
GO

PRINT 'All Reporting Views Created Successfully inside dbo schema.';