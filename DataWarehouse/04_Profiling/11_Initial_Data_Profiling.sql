/*
===============================================================================
Project: OULAD Data Warehouse (DEPI Graduation Project)
Script: Initial Data Profiling & Quality Assessment
Description:
    - Analyzes raw Bronze data to identify quality issues.
    - Documents anomalies such as double quotes, NULLs, and logical errors.
    - Decisions derived from this report are implemented in the Silver Layer.
===============================================================================
*/

USE oulad_warehouse;
GO

-----------------------------------------------------------
-- 1. PROFILING: Bronze.courses
-----------------------------------------------------------
/*
    Problem Report:
    - Data ingested with double quotes ("") in all fields.
    - No other structural issues identified.

    Decisions:
    - Sanitize data by removing double quotes.
    - Derive 'semester' column for better grouping.
    - Implement correct numeric data types in Silver layer.
*/

PRINT 'TESTING: Bronze.courses';
SELECT TOP 5 * FROM Bronze.courses;

SELECT 
    'Duplicate Course Key' AS Test_Name,
    COUNT(*) - COUNT(DISTINCT REPLACE(code_module, '"', '') + REPLACE(code_presentation, '"', '')) AS Problem_Count
FROM Bronze.courses;

-----------------------------------------------------------
-- 2. PROFILING: Bronze.assessments
-----------------------------------------------------------
/*
    Problem Report:
    - Double quotes detected.
    - 11 records missing dates (primarily Exam types).

    Decisions:
    - Remove double quotes.
    - Impute missing dates using 'module_presentation_length' from courses.
    - Derive 'is_final_exam' flag for analysis.
*/

PRINT 'TESTING: Bronze.assessments';
SELECT 
    'Missing Dates' AS Test_Name, 
    COUNT(*) AS Problem_Count
FROM Bronze.assessments
WHERE [date] IS NULL OR TRIM([date]) = '' OR TRIM([date]) = '""';

-----------------------------------------------------------
-- 3. PROFILING: Bronze.studentRegistration
-----------------------------------------------------------
/*
    Problem Report:
    - 222 logical errors found where Unregistration Date < Registration Date.
    - 45 records missing Registration Date.

    Decisions:
    - Clean double quotes.
    - Impute missing registration dates using first VLE interaction date.
    - Set logically inconsistent unregistration dates to NULL.
    - Derive 'days_enrolled' and 'is_active' columns.
*/

PRINT 'TESTING: Bronze.studentRegistration';
-- Audit Summary: Logical Classification of Records
WITH AuditLogic AS (
    SELECT 
        CASE 
            WHEN TRY_CAST(REPLACE(date_unregistration, '"', '') AS INT) < 
                 TRY_CAST(REPLACE(date_registration, '"', '') AS INT) 
                 THEN 'Logical Error (Unreg < Reg)'
            WHEN REPLACE(date_registration, '"', '') = '' OR date_registration IS NULL 
                 THEN 'Missing Registration Date'
            WHEN REPLACE(date_unregistration, '"', '') <> '' AND REPLACE(final_result, '"', '') <> 'Withdrawn' 
                 THEN 'Inconsistency: Pass/Fail with Unreg Date'
            ELSE 'Healthy Record'
        END AS Status_Category
    FROM Bronze.studentRegistration Reg
    INNER JOIN Bronze.studentInfo Info 
        ON  REPLACE(Reg.code_module, '"', '') = REPLACE(Info.code_module, '"', '')
        AND REPLACE(Reg.code_presentation, '"', '') = REPLACE(Info.code_presentation, '"', '')
        AND REPLACE(Reg.id_student, '"', '') = REPLACE(Info.id_student, '"', '')
)
SELECT 
    Status_Category, 
    COUNT(*) AS Total_Count,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS Percentage
FROM AuditLogic
GROUP BY Status_Category;