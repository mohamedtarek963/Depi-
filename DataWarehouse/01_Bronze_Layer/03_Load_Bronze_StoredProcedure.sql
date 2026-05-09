/*
===============================================================================
Stored Procedure: Bronze.load_Bronze
Description: 
    - Loads raw data from CSV files to the Bronze layer tables.
    - Performs validation to ensure row counts match the expected values.
    - Tracks execution duration per table.
    - Handles errors using TRY...CATCH.
Usage: EXEC Bronze.load_Bronze;

BY\ Abdelrahman Ahmed
===============================================================================
*/
USE oulad_warehouse
GO
EXEC Bronze.load_Bronze
GO

CREATE OR ALTER PROCEDURE Bronze.load_Bronze AS
BEGIN
-- Declare variables for row count validation and performance tracking
    DECLARE @row_count INT,
            @start_time DATETIME,
            @end_time DATETIME;
    BEGIN TRY
-----------------------------------------------------------------------
        -- Loading Bronze Layer: Data Ingestion & Validation --
-----------------------------------------------------------------------
        SET @start_time = GETDATE();
        TRUNCATE TABLE bronze.assessments;
        BULK INSERT bronze.assessments
        FROM 'YOUR_LOCAL_PATH\OULAD\assessments.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK,
            ERRORFILE = 'YOUR_LOCAL_PATH\Errors_logs\assessments_Errors.log',
            MAXERRORS = 100
        );
        SELECT @row_count = COUNT(*) FROM bronze.assessments;
        IF @row_count <> 206
        BEGIN
            PRINT 'Error: assessments count mismatch. Expected 206, but got ' + CAST(@row_count AS VARCHAR);
            RETURN;
        END
        SET @end_time = GETDATE();
        PRINT 'Assessments loaded in ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds.';


        SET @start_time = GETDATE();
        TRUNCATE TABLE bronze.courses;
        BULK INSERT bronze.courses
        FROM 'YOUR_LOCAL_PATH\courses.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK,
            ERRORFILE = 'YOUR_LOCAL_PATH\Errors_logs\courses_Errors.log',
            MAXERRORS = 100
        );
        SELECT @row_count = COUNT(*) FROM bronze.courses;
        IF @row_count <> 22
        BEGIN
            PRINT 'Error: courses count mismatch. Expected 22, but got ' + CAST(@row_count AS VARCHAR);
            RETURN;
        END
        SET @end_time = GETDATE();
        PRINT 'Courses loaded in ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds.';


        SET @start_time = GETDATE();
        TRUNCATE TABLE bronze.studentAssessment;
        BULK INSERT bronze.studentAssessment
        FROM 'YOUR_LOCAL_PATH\studentAssessment.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK,
            ERRORFILE = 'YOUR_LOCAL_PATH\Errors_logs\studentAssessment_Errors.log',
            MAXERRORS = 100
        );
        SELECT @row_count = COUNT(*) FROM bronze.studentAssessment;
        IF @row_count <> 173912
        BEGIN
            PRINT 'Error: studentAssessment count mismatch. Expected 173912, but got ' + CAST(@row_count AS VARCHAR);
            RETURN;
        END
        SET @end_time = GETDATE();
        PRINT 'StudentAssessment loaded in ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds.';


        SET @start_time = GETDATE();
        TRUNCATE TABLE bronze.studentInfo;
        BULK INSERT bronze.studentInfo
        FROM 'YOUR_LOCAL_PATH\studentInfo.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK,
            ERRORFILE = 'YOUR_LOCAL_PATH\Errors_logs\studentInfo_Errors.log',
            MAXERRORS = 100
        );
        SELECT @row_count = COUNT(*) FROM bronze.studentInfo;
        IF @row_count <> 32593
        BEGIN
            PRINT 'Error: studentInfo count mismatch. Expected 32593, but got ' + CAST(@row_count AS VARCHAR);
            RETURN;
        END
        SET @end_time = GETDATE();
        PRINT 'StudentInfo loaded in ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds.';

        SET @start_time = GETDATE();
        TRUNCATE TABLE bronze.studentRegistration;
        BULK INSERT bronze.studentRegistration
        FROM 'YOUR_LOCAL_PATH\studentRegistration.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK,
            ERRORFILE = 'YOUR_LOCAL_PATH\Errors_logs\studentRegistration_Errors.log',
            MAXERRORS = 100
        );
        SELECT @row_count = COUNT(*) FROM bronze.studentRegistration;
        IF @row_count <> 32593
        BEGIN
            PRINT 'Error: studentRegistration count mismatch. Expected 32593, but got ' + CAST(@row_count AS VARCHAR);
            RETURN;
        END
        SET @end_time = GETDATE();
        PRINT 'StudentRegistration loaded in ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds.';


        SET @start_time = GETDATE();
        TRUNCATE TABLE bronze.studentVle;
        BULK INSERT bronze.studentVle
        FROM 'YOUR_LOCAL_PATH\studentVle.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK,
            ERRORFILE = 'YOUR_LOCAL_PATH\Errors_logs\studentVle_Errors.log',
            MAXERRORS = 100
        );
        SELECT @row_count = COUNT(*) FROM bronze.studentVle;
        IF @row_count <> 10655280
        BEGIN
            PRINT 'Error: studentVle count mismatch. Expected 10655280, but got ' + CAST(@row_count AS VARCHAR);
            RETURN;
        END
        SET @end_time = GETDATE();
        PRINT 'StudentVle loaded in ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds.';

        SET @start_time = GETDATE();
        TRUNCATE TABLE bronze.VLE;
        BULK INSERT bronze.VLE
        FROM 'YOUR_LOCAL_PATH\VLE.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK,
            ERRORFILE = 'YOUR_LOCAL_PATH\Errors_logs\VLE_Errors.log',
            MAXERRORS = 100
        );
        SELECT @row_count = COUNT(*) FROM bronze.VLE;
        IF @row_count <> 6364
        BEGIN
            PRINT 'Error: VLE count mismatch. Expected 6364, but got ' + CAST(@row_count AS VARCHAR);
            RETURN;
        END
        SET @end_time = GETDATE();
        PRINT 'VLE loaded in ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds.';
    END TRY
    BEGIN CATCH
    -- Error Handling Block
        PRINT '================================================';
        PRINT 'CRITICAL ERROR: The process stopped.';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR);
        PRINT '================================================';
    END CATCH
END;
