/* ===============================================================================
Stored Procedure: Gold.load_Gold
Description:
    Orchestrates the full load from Silver to Gold in dependency order.

    Execution Order:
        1. Dim_Modules_Catalog    (no dependencies)
        2. Dim_Assessments_Info   (depends on: Dim_Modules_Catalog)
        3. Dim_Students_Profile   (depends on: Dim_Modules_Catalog)
        4. Dim_Vle_Resources      (depends on: Dim_Modules_Catalog)
        5. Fact_Enrollment        (depends on: Dim_Students_Profile, Dim_Modules_Catalog)
        6. Fact_Student_Scores    (depends on: Dim_Students_Profile, Dim_Assessments_Info)
        7. Fact_Student_Vle_Clicks(depends on: Dim_Students_Profile, Dim_Vle_Resources)

Usage: EXEC Gold.load_Gold;

BY\ Abdelrahman Ahmed
=============================================================================== */
GO

CREATE OR ALTER PROCEDURE Gold.load_Gold AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time  DATETIME = GETDATE();
    DECLARE @step_start  DATETIME;
    DECLARE @row_count   INT;
    DECLARE @total_rows  INT = 0;

    BEGIN TRY
        PRINT '##################################################';
        PRINT '# GOLD LAYER REFRESH                            #';
        PRINT '# Started: ' + CONVERT(VARCHAR, @start_time, 120) + '         #';
        PRINT '##################################################';


/* ===============================================================================
        STEP 1: Dim_Modules_Catalog
=============================================================================== */
        SET @step_start = GETDATE();
        PRINT '';
        PRINT '================================================';
        PRINT 'STEP 1 | LOADING: Silver.courses -> Gold.Dim_Modules_Catalog';
        PRINT '================================================';

        TRUNCATE TABLE Gold.Dim_Modules_Catalog;

        INSERT INTO Gold.Dim_Modules_Catalog (
            Module_Key,
            module_presentation_length,
            semester
            )
        SELECT
            code_module + '-' + code_presentation,
            module_presentation_length,
            semester
        FROM Silver.courses;

        SET @row_count = @@ROWCOUNT;
        SET @total_rows += @row_count;
        PRINT 'SUCCESS: ' + CAST(@row_count AS VARCHAR) + ' rows loaded. (' + CAST(DATEDIFF(SECOND, @step_start, GETDATE()) AS VARCHAR) + 's)';
        PRINT '================================================';


/* ===============================================================================
        STEP 2: Dim_Assessments_Info
=============================================================================== */
        SET @step_start = GETDATE();
        PRINT '';
        PRINT '================================================';
        PRINT 'STEP 2 | LOADING: Silver.assessments -> Gold.Dim_Assessments_Info';
        PRINT '================================================';

        TRUNCATE TABLE Gold.Dim_Assessments_Info;

        INSERT INTO Gold.Dim_Assessments_Info (
            id_assessment,
            Module_Key,
            assessment_type,
            [date],
            [weight],
            is_final_exam
            )
        SELECT
            id_assessment,
            code_module + '-' + code_presentation,
            assessment_type,
            [date],
            [weight],
            is_final_exam
        FROM Silver.assessments;

        SET @row_count = @@ROWCOUNT;
        SET @total_rows += @row_count;
        PRINT 'SUCCESS: ' + CAST(@row_count AS VARCHAR) + ' rows loaded. (' + CAST(DATEDIFF(SECOND, @step_start, GETDATE()) AS VARCHAR) + 's)';
        PRINT '================================================';


/* ===============================================================================
        STEP 3: Dim_Students_Profile
=============================================================================== */
        SET @step_start = GETDATE();
        PRINT '';
        PRINT '================================================';
        PRINT 'STEP 3 | LOADING: Silver.studentInfo -> Gold.Dim_Students_Profile';
        PRINT '================================================';

        TRUNCATE TABLE Gold.Dim_Students_Profile;

        INSERT INTO Gold.Dim_Students_Profile (
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
        )
        SELECT
            code_module + '-' + code_presentation + '-' + CAST(id_student AS VARCHAR),
            code_module + '-' + code_presentation,
            gender,
            region,
            highest_education,
            imd_band,
            age_band,
            num_of_prev_attempts,
            studied_credits,
            disability
        FROM Silver.studentInfo;

        SET @row_count = @@ROWCOUNT;
        SET @total_rows += @row_count;
        PRINT 'SUCCESS: ' + CAST(@row_count AS VARCHAR) + ' rows loaded. (' + CAST(DATEDIFF(SECOND, @step_start, GETDATE()) AS VARCHAR) + 's)';
        PRINT '================================================';


/* ===============================================================================
        STEP 4: Dim_Vle_Resources
=============================================================================== */
        SET @step_start = GETDATE();
        PRINT '';
        PRINT '================================================';
        PRINT 'STEP 4 | LOADING: Silver.vle -> Gold.Dim_Vle_Resources';
        PRINT '================================================';

        TRUNCATE TABLE Gold.Dim_Vle_Resources;

        INSERT INTO Gold.Dim_Vle_Resources (
            id_site,
            Module_Key,
            activity_type,
            week_from,
            week_to
        )
        SELECT
            id_site,
            code_module + '-' + code_presentation,
            activity_type,
            week_from,
            week_to
        FROM Silver.vle;

        SET @row_count = @@ROWCOUNT;
        SET @total_rows += @row_count;
        PRINT 'SUCCESS: ' + CAST(@row_count AS VARCHAR) + ' rows loaded. (' + CAST(DATEDIFF(SECOND, @step_start, GETDATE()) AS VARCHAR) + 's)';
        PRINT '================================================';


/* ===============================================================================
        STEP 5: Fact_Enrollment
        Note: final_result is the model target variable — lives here, not in Dim.
=============================================================================== */
        SET @step_start = GETDATE();
        PRINT '';
        PRINT '================================================';
        PRINT 'STEP 5 | LOADING: Silver.studentRegistration + Silver.studentInfo -> Gold.Fact_Enrollment';
        PRINT '================================================';

        TRUNCATE TABLE Gold.Fact_Enrollment;

        INSERT INTO Gold.Fact_Enrollment (
            Student_Key,
            Module_Key,
            date_registration,
            date_unregistration,
            is_active,
            days_enrolled,
            final_result
        )
        SELECT
            SR.code_module + '-' + SR.code_presentation + '-' + CAST(SR.id_student AS VARCHAR),
            SR.code_module + '-' + SR.code_presentation,
            SR.date_registration,
            SR.date_unregistration,
            SR.is_active,
            SR.days_enrolled,
            SI.final_result
        FROM Silver.studentRegistration SR
        LEFT JOIN Silver.studentInfo SI
            ON  SR.id_student        = SI.id_student
            AND SR.code_module       = SI.code_module
            AND SR.code_presentation = SI.code_presentation;

        SET @row_count = @@ROWCOUNT;
        SET @total_rows += @row_count;
        PRINT 'SUCCESS: ' + CAST(@row_count AS VARCHAR) + ' rows loaded. (' + CAST(DATEDIFF(SECOND, @step_start, GETDATE()) AS VARCHAR) + 's)';
        PRINT '================================================';


/* ===============================================================================
        STEP 6: Fact_Student_Scores
=============================================================================== */
        SET @step_start = GETDATE();
        PRINT '';
        PRINT '================================================';
        PRINT 'STEP 6 | LOADING: Silver.studentAssessment -> Gold.Fact_Student_Scores';
        PRINT '================================================';

        TRUNCATE TABLE Gold.Fact_Student_Scores;

        INSERT INTO Gold.Fact_Student_Scores (
            Student_Key,
            Module_Key,
            id_assessment,
            date_submitted,
            score,
            weighted_score,
            is_late_submission
        )
        SELECT
            A.code_module + '-' + A.code_presentation + '-' + CAST(SA.id_student AS VARCHAR),
            A.code_module + '-' + A.code_presentation,
            SA.id_assessment,
            SA.date_submitted,
            SA.score,
            SA.weighted_score,
            SA.is_late_submission
        FROM Silver.studentAssessment SA
        INNER JOIN Silver.assessments A
            ON SA.id_assessment = A.id_assessment;

        SET @row_count = @@ROWCOUNT;
        SET @total_rows += @row_count;
        PRINT 'SUCCESS: ' + CAST(@row_count AS VARCHAR) + ' rows loaded. (' + CAST(DATEDIFF(SECOND, @step_start, GETDATE()) AS VARCHAR) + 's)';
        PRINT '================================================';


/* ===============================================================================
        STEP 7: Fact_Student_Vle_Clicks
=============================================================================== */
        SET @step_start = GETDATE();
        PRINT '';
        PRINT '================================================';
        PRINT 'STEP 7 | LOADING: Silver.studentVle -> Gold.Fact_Student_Vle_Clicks';
        PRINT '================================================';

        TRUNCATE TABLE Gold.Fact_Student_Vle_Clicks;

        INSERT INTO Gold.Fact_Student_Vle_Clicks (
            Student_Key,
            Module_Key,
            id_site,
            [date],
            sum_click
        )
        SELECT
            code_module + '-' + code_presentation + '-' + CAST(id_student AS VARCHAR),
            code_module + '-' + code_presentation,
            id_site,
            [date],
            SUM(sum_click)
        FROM Silver.studentVle
        GROUP BY code_module, code_presentation, id_student, id_site, [date];
        SET @row_count = @@ROWCOUNT;
        SET @total_rows += @row_count;
        PRINT 'SUCCESS: ' + CAST(@row_count AS VARCHAR) + ' rows loaded. (' + CAST(DATEDIFF(SECOND, @step_start, GETDATE()) AS VARCHAR) + 's)';
        PRINT '================================================';


/* ===============================================================================
        MASTER SUMMARY
=============================================================================== */
        PRINT '';
        PRINT '##################################################';
        PRINT '# GOLD LAYER REFRESH COMPLETE                   #';
        PRINT '# Total Rows Loaded : ' + CAST(@total_rows AS VARCHAR);
        PRINT '# Total Duration    : ' + CAST(DATEDIFF(SECOND, @start_time, GETDATE()) AS VARCHAR) + ' seconds';
        PRINT '##################################################';

    END TRY
    BEGIN CATCH
        PRINT '';
        PRINT '##################################################';
        PRINT '# GOLD LAYER REFRESH FAILED                     #';
        PRINT '# Error: ' + ERROR_MESSAGE();
        PRINT '##################################################';
    END CATCH
END;
GO

-- Active 
EXEC Gold.load_Gold;
GO