/*
===============================================================================
Script: Bronze Layer Validation
Description: 
    - Provides a quick summary of row counts and sample data from each table.
    - Used to verify that the ingestion process completed as expected.
===============================================================================
*/

USE oulad_warehouse;
GO

PRINT '--- Table: Bronze.assessments ---';
SELECT TOP 3 * FROM Bronze.assessments;
SELECT COUNT(*) AS total_rows FROM Bronze.assessments;

PRINT '--- Table: Bronze.courses ---';
SELECT TOP 3 * FROM Bronze.courses;
SELECT COUNT(*) AS total_rows FROM Bronze.courses;

PRINT '--- Table: Bronze.studentAssessment ---';
SELECT TOP 3 * FROM Bronze.studentAssessment;
SELECT COUNT(*) AS total_rows FROM Bronze.studentAssessment;

PRINT '--- Table: Bronze.studentInfo ---';
SELECT TOP 3 * FROM Bronze.studentInfo;
SELECT COUNT(*) AS total_rows FROM Bronze.studentInfo;

PRINT '--- Table: Bronze.studentRegistration ---';
SELECT TOP 3 * FROM Bronze.studentRegistration;
SELECT COUNT(*) AS total_rows FROM Bronze.studentRegistration;

PRINT '--- Table: Bronze.studentVle ---';
SELECT TOP 3 * FROM Bronze.studentVle;
SELECT COUNT(*) AS total_rows FROM Bronze.studentVle;

PRINT '--- Table: Bronze.VLE ---';
SELECT TOP 3 * FROM Bronze.VLE;
SELECT COUNT(*) AS total_rows FROM Bronze.VLE;