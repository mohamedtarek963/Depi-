/*
===============================================================================
Project: OULAD Data Warehouse (DEPI Graduation Project)
Layer: Silver (Cleansed & Processed Data)
Description: 
    - Initializes the schema for the Silver layer.
    - Defines optimized data types (INT, FLOAT, CHAR, BIT).
    - Includes derived columns for behavioral analysis.
===============================================================================
*/

USE oulad_warehouse;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Silver')
    EXEC('CREATE SCHEMA Silver');
GO

-- 1. Silver.assessments
IF OBJECT_ID ('Silver.assessments','U') IS NOT NULL DROP TABLE Silver.assessments;
CREATE TABLE Silver.assessments (
    id_assessment      INT,
    code_module        VARCHAR(10),
    code_presentation  VARCHAR(10),
    assessment_type    VARCHAR(10),
    [date]             INT,
    [weight]           FLOAT,
    semester           VARCHAR(10),
    is_final_exam      BIT,
    load_timestamp     DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (id_assessment)
);

-- 2. Silver.courses
IF OBJECT_ID ('Silver.courses','U') IS NOT NULL DROP TABLE Silver.courses;
CREATE TABLE Silver.courses (
    code_module                VARCHAR(10),
    code_presentation          VARCHAR(10),
    module_presentation_length INT,
    semester                   VARCHAR(10),
    load_timestamp             DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (code_module, code_presentation)
);

-- 3. Silver.studentAssessment
IF OBJECT_ID ('Silver.studentAssessment','U') IS NOT NULL DROP TABLE Silver.studentAssessment;
CREATE TABLE Silver.studentAssessment (
    id_assessment      INT,
    id_student         INT,
    date_submitted     INT,
    is_banked          BIT,
    score              FLOAT,
    weighted_score     FLOAT,
    is_late_submission BIT,
    load_timestamp     DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (id_assessment, id_student)
);

-- 4. Silver.studentInfo
IF OBJECT_ID ('Silver.studentInfo','U') IS NOT NULL DROP TABLE Silver.studentInfo;
CREATE TABLE Silver.studentInfo (
    code_module           VARCHAR(10),
    code_presentation     VARCHAR(10),
    id_student            INT,
    gender                CHAR(1),
    region                VARCHAR(100),
    highest_education     VARCHAR(100),
    imd_band              VARCHAR(20), 
    age_band              VARCHAR(20), 
    num_of_prev_attempts  INT,
    studied_credits       INT,
    disability            CHAR(1),
    final_result          VARCHAR(20),
    load_timestamp        DATETIME DEFAULT GETDATE()
);

-- 5. Silver.studentRegistration
IF OBJECT_ID ('Silver.studentRegistration','U') IS NOT NULL DROP TABLE Silver.studentRegistration;
CREATE TABLE Silver.studentRegistration (
    code_module         VARCHAR(10),
    code_presentation   VARCHAR(10),
    id_student          INT,
    date_registration   INT,
    date_unregistration INT,
    is_active           INT,
    days_enrolled       INT,
    is_imputed          INT,
    load_timestamp      DATETIME DEFAULT GETDATE()
);

-- 6. Silver.studentVle (Clustered for 10M+ rows performance)
IF OBJECT_ID ('Silver.studentVle','U') IS NOT NULL DROP TABLE Silver.studentVle;
CREATE TABLE Silver.studentVle (
    code_module       VARCHAR(10),
    code_presentation VARCHAR(10),
    id_student        INT,
    id_site           INT,
    [date]            INT,
    sum_click         INT,
    load_timestamp    DATETIME DEFAULT GETDATE()
);
CREATE CLUSTERED INDEX IX_studentVle_Main ON Silver.studentVle (id_student, code_module, code_presentation);

-- 7. Silver.vle
IF OBJECT_ID ('Silver.vle','U') IS NOT NULL DROP TABLE Silver.vle;
CREATE TABLE Silver.vle (
    id_site           INT PRIMARY KEY,
    code_module       VARCHAR(10),
    code_presentation VARCHAR(10),
    activity_type     VARCHAR(50),
    week_from         INT,
    week_to           INT,
    is_week_imputed   BIT NOT NULL DEFAULT 0,
    load_timestamp    DATETIME DEFAULT GETDATE()
);