/*
===============================================================================
Project: OULAD Data Warehouse
Layer: Bronze (Raw Data Ingestion)
Description: 
    - Initializes the raw tables for the OULAD dataset.
    - All columns are defined as VARCHAR to ensure successful Bulk Ingestion 
      without data type mismatch errors. 
    - Type casting and cleaning will be performed in the Silver Layer.

BY\ Abdelrahman Ahmed
===============================================================================
*/

USE oulad_warehouse;
GO
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Bronze')
BEGIN
    EXEC('CREATE SCHEMA Bronze');
END
GO

IF OBJECT_ID ('Bronze.assessments','U') IS NOT NULL
    DROP TABLE Bronze.assessments;
CREATE TABLE Bronze.assessments(
    code_module         VARCHAR(10),
    code_presentation   VARCHAR(10),
    id_assessment       VARCHAR(20),
    assessment_type     VARCHAR(20),
    [date]     VARCHAR(20),
    [weight]   VARCHAR(20)
)
PRINT('Table Assessments Created Successfully (Bronze)')
GO

IF OBJECT_ID ('Bronze.courses','U') IS NOT NULL
    DROP TABLE Bronze.courses;
CREATE TABLE Bronze.courses(
    code_module                     VARCHAR(10),
    code_presentation               VARCHAR(10),
    module_presentation_length      VARCHAR(20)
)
PRINT('Table Courses Created Successfully (Bronze)')
GO

IF OBJECT_ID ('Bronze.studentAssessment','U') IS NOT NULL
    DROP TABLE Bronze.studentAssessment;
CREATE TABLE Bronze.studentAssessment(
    id_assessment       VARCHAR(20),
    id_student          VARCHAR(20),
    date_submitted      VARCHAR(20),
    is_banked           VARCHAR(5),
    score               VARCHAR(20)
)
PRINT('Table studentAssessment Created Successfully (Bronze)')
GO

IF OBJECT_ID ('Bronze.studentInfo','U') IS NOT NULL
    DROP TABLE Bronze.studentInfo;
CREATE TABLE Bronze.studentInfo(
    code_module             VARCHAR(10),
    code_presentation       VARCHAR(10),
    id_student              VARCHAR(20),
    gender                  VARCHAR(5),
    region                  VARCHAR(50),
    highest_education       VARCHAR(50),
    imd_band                VARCHAR(20),
    age_band                VARCHAR(20),
    num_of_prev_attempts    VARCHAR(10),
    studied_credits         VARCHAR(10),
    disability              VARCHAR(10),
    final_result            VARCHAR(20)
)
PRINT('Table studentInfo Created Successfully (Bronze)')
GO

IF OBJECT_ID ('Bronze.studentRegistration','U') IS NOT NULL
    DROP TABLE Bronze.studentRegistration;
CREATE TABLE Bronze.studentRegistration(
    code_module             VARCHAR(10),
    code_presentation       VARCHAR(10),
    id_student              VARCHAR(20),
    date_registration       VARCHAR(20),
    date_unregistration     VARCHAR(20)
)
PRINT('Table studentRegistration Created Successfully (Bronze)')
GO

IF OBJECT_ID ('Bronze.studentVle','U') IS NOT NULL
    DROP TABLE Bronze.studentVle;
CREATE TABLE Bronze.studentVle(
    code_module         VARCHAR(10),
    code_presentation   VARCHAR(10),
    id_student          VARCHAR(20),
    id_site             VARCHAR(20),
    studentVle_date     VARCHAR(20),
    sum_click           VARCHAR(20)
)
PRINT('Table studentVle Created Successfully (Bronze)')
GO

IF OBJECT_ID ('Bronze.VLE','U') IS NOT NULL
    DROP TABLE Bronze.VLE;
CREATE TABLE Bronze.VLE(
    id_site             VARCHAR(20),
    code_module         VARCHAR(10),
    code_presentation   VARCHAR(10),
    activity_type       VARCHAR(20),
    week_from           VARCHAR(20),
    week_to             VARCHAR(20)
)
PRINT('Table VLE Created Successfully (Bronze)')

PRINT('Tables Created Successfully (Bronze)')