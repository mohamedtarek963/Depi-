/* ===============================================================================
Project: OULAD Data Warehouse
Layer: Gold (Analytical & Model-Ready Data)
Description:
    - Dimension and Fact tables for the Gold layer.
    - Surrogate Keys: Module_Key (module + presentation), Student_Key (module + presentation + student).
    - final_result moved to Fact_Enrollment as the model target variable.
    - Primary Keys added to all Fact tables to prevent duplicates.
    - Module_Key added to Fact tables for direct joins.
    - load_timestamp added to all tables for audit.
BY\ Abdelrahman Ahmed
=============================================================================== */

USE oulad_warehouse;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Gold')
    EXEC('CREATE SCHEMA Gold');
GO
IF OBJECT_ID('Gold.Dim_Modules_Catalog', 'U') IS NOT NULL DROP TABLE Gold.Dim_Modules_Catalog;
IF OBJECT_ID('Gold.Dim_Assessments_Info', 'U') IS NOT NULL DROP TABLE Gold.Dim_Assessments_Info;
IF OBJECT_ID('Gold.Dim_Students_Profile', 'U') IS NOT NULL DROP TABLE Gold.Dim_Students_Profile;
IF OBJECT_ID('Gold.Dim_Vle_Resources', 'U') IS NOT NULL DROP TABLE Gold.Dim_Vle_Resources;
IF OBJECT_ID('Gold.Fact_Enrollment', 'U') IS NOT NULL DROP TABLE Gold.Fact_Enrollment;
IF OBJECT_ID('Gold.Fact_Student_Scores', 'U') IS NOT NULL DROP TABLE Gold.Fact_Student_Scores;
IF OBJECT_ID('Gold.Fact_Student_Vle_Clicks', 'U') IS NOT NULL DROP TABLE Gold.Fact_Student_Vle_Clicks;
GO

-- 1. Dim_Modules_Catalog
CREATE TABLE Gold.Dim_Modules_Catalog (
    Module_Key                 VARCHAR(30)  NOT NULL,
    module_presentation_length INT,
    semester                   VARCHAR(20),
    load_timestamp             DATETIME     DEFAULT GETDATE(),
    PRIMARY KEY (Module_Key)
);

-- 2. Dim_Assessments_Info
CREATE TABLE Gold.Dim_Assessments_Info (
    id_assessment   INT          NOT NULL,
    Module_Key      VARCHAR(30)  NOT NULL,
    assessment_type VARCHAR(20),
    [date]          INT,
    [weight]        FLOAT,
    is_final_exam   BIT,
    load_timestamp  DATETIME     DEFAULT GETDATE(),
    PRIMARY KEY (id_assessment),
    FOREIGN KEY (Module_Key) REFERENCES Gold.Dim_Modules_Catalog(Module_Key)
);

-- 3. Dim_Students_Profile
CREATE TABLE Gold.Dim_Students_Profile (
    Student_Key          VARCHAR(50)  NOT NULL,
    Module_Key           VARCHAR(30)  NOT NULL,
    gender               CHAR(1),
    region               VARCHAR(100),
    highest_education    VARCHAR(100),
    imd_band             VARCHAR(20),
    age_band             VARCHAR(20),
    num_of_prev_attempts INT,
    studied_credits      INT,
    disability           CHAR(1),
    load_timestamp       DATETIME     DEFAULT GETDATE(),
    PRIMARY KEY (Student_Key),
    FOREIGN KEY (Module_Key) REFERENCES Gold.Dim_Modules_Catalog(Module_Key)
);

-- 4. Dim_Vle_Resources
CREATE TABLE Gold.Dim_Vle_Resources (
    id_site        INT          NOT NULL,
    Module_Key     VARCHAR(30)  NOT NULL,
    activity_type  VARCHAR(50),
    week_from      INT,
    week_to        INT,
    load_timestamp DATETIME     DEFAULT GETDATE(),
    PRIMARY KEY (id_site),
    FOREIGN KEY (Module_Key) REFERENCES Gold.Dim_Modules_Catalog(Module_Key)
);

-- 5. Fact_Enrollment
CREATE TABLE Gold.Fact_Enrollment (
    Student_Key         VARCHAR(50)  NOT NULL,
    Module_Key          VARCHAR(30)  NOT NULL,
    date_registration   INT,
    date_unregistration INT,
    is_active           INT,
    days_enrolled       INT,
    final_result        VARCHAR(20),
    load_timestamp      DATETIME     DEFAULT GETDATE(),
    PRIMARY KEY (Student_Key, Module_Key),
    FOREIGN KEY (Student_Key) REFERENCES Gold.Dim_Students_Profile(Student_Key),
    FOREIGN KEY (Module_Key) REFERENCES Gold.Dim_Modules_Catalog(Module_Key)
);

-- 6. Fact_Student_Scores
CREATE TABLE Gold.Fact_Student_Scores (
    Student_Key        VARCHAR(50)  NOT NULL,
    id_assessment      INT          NOT NULL,
    date_submitted     INT,
    score              FLOAT,
    weighted_score     FLOAT,
    is_late_submission BIT,
    load_timestamp     DATETIME     DEFAULT GETDATE(),
    PRIMARY KEY (Student_Key, id_assessment),
    FOREIGN KEY (Student_Key) REFERENCES Gold.Dim_Students_Profile(Student_Key),
    FOREIGN KEY (id_assessment) REFERENCES Gold.Dim_Assessments_Info(id_assessment)
)

-- 7. Fact_Student_Vle_Clicks
CREATE TABLE Gold.Fact_Student_Vle_Clicks (
    Student_Key    VARCHAR(50)  NOT NULL,
    id_site        INT          NOT NULL,
    [date]         INT          NOT NULL,
    sum_click      INT,
    load_timestamp DATETIME     DEFAULT GETDATE(),
    PRIMARY KEY (Student_Key, id_site, [date]),
    FOREIGN KEY (Student_Key) REFERENCES Gold.Dim_Students_Profile(Student_Key),
    FOREIGN KEY (id_site) REFERENCES Gold.Dim_Vle_Resources(id_site)
);
GO