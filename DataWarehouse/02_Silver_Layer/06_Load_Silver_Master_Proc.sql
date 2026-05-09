/* ===============================================================================
Master Stored Procedure: Silver.load_Silver
Description:
    Orchestrates the full cleaning and transformation pipeline from Bronze to Silver.
    Executes all table loads in dependency order.

    Execution Order:
        1. Silver.courses             (no dependencies)
        2. Silver.vle                 (no dependencies)
        3. Silver.assessments         (depends on: Silver.courses)
        4. Silver.studentInfo         (no dependencies)
        5. Silver.studentVle          (no dependencies)
        6. Silver.studentAssessment   (depends on: Silver.assessments)
        7. Silver.studentRegistration (depends on: Silver.studentInfo, Silver.studentVle)

Usage: EXEC Silver.load_Silver;
BY\ Abdelrahman Ahmed
=============================================================================== */
USE oulad_warehouse;
GO

CREATE OR ALTER PROCEDURE Silver.load_Silver AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time  DATETIME = GETDATE();
    DECLARE @step_start  DATETIME;
    DECLARE @row_count   INT;
    DECLARE @total_rows  INT = 0;

    BEGIN TRY
        PRINT '##################################################';
        PRINT '# MASTER LOAD: Bronze -> Silver                  #';
        PRINT '# Started: ' + CONVERT(VARCHAR, @start_time, 120) + '    #';
        PRINT '##################################################';


/* ===============================================================================
    STEP 1: Silver.courses
    - Removes double quotes and trims whitespace.
    - Derives semester from code_presentation suffix.
=============================================================================== */
        SET @step_start = GETDATE();
        TRUNCATE TABLE Silver.courses;

        INSERT INTO Silver.courses (
            code_module, code_presentation,
            module_presentation_length, semester, load_timestamp
        )
        SELECT 
            TRIM(REPLACE(code_module,                '"', '')),
            TRIM(REPLACE(code_presentation,          '"', '')),
            TRIM(REPLACE(module_presentation_length, '"', '')),
            CASE 
                WHEN TRIM(REPLACE(code_presentation, '"', '')) LIKE '%B' THEN 'Spring'
                WHEN TRIM(REPLACE(code_presentation, '"', '')) LIKE '%J' THEN 'Autumn'
                ELSE 'Unknown'
            END,
            GETDATE()
        FROM Bronze.courses;

        SET @row_count = @@ROWCOUNT;
        SET @total_rows += @row_count;
        PRINT 'STEP 1 SUCCESS: ' + CAST(@row_count AS VARCHAR) + ' rows -> Silver.courses. (' + CAST(DATEDIFF(SECOND, @step_start, GETDATE()) AS VARCHAR) + 's)';


/* ===============================================================================
    STEP 2: Silver.vle
    - Removes double quotes and trims whitespace.
    - Imputes missing week values with 0.
    - FIX: Corrected column order (is_week_imputed was swapped with week_from).
=============================================================================== */
        SET @step_start = GETDATE();
        TRUNCATE TABLE Silver.vle;

        INSERT INTO Silver.vle (
            id_site, code_module, code_presentation,
            activity_type, week_from, week_to,
            is_week_imputed, load_timestamp
        )
        SELECT 
            TRY_CAST(TRIM(REPLACE(id_site,        '"', '')) AS INT),
            TRIM(REPLACE(code_module,             '"', '')),
            TRIM(REPLACE(code_presentation,       '"', '')),
            TRIM(REPLACE(activity_type,           '"', '')),
            -- FIX: week_from value goes into week_from column
            ISNULL(TRY_CAST(TRIM(REPLACE(week_from, '"', '')) AS INT), 0),
            -- FIX: week_to value goes into week_to column
            ISNULL(TRY_CAST(TRIM(REPLACE(week_to,   '"', '')) AS INT), 0),
            -- FIX: flag goes into is_week_imputed column
            CASE 
                WHEN TRIM(REPLACE(week_from, '"', '')) IN ('?', '') 
                  OR week_from IS NULL THEN 1 
                ELSE 0 
            END,
            GETDATE()
        FROM Bronze.vle;

        SET @row_count = @@ROWCOUNT;
        SET @total_rows += @row_count;
        PRINT 'STEP 2 SUCCESS: ' + CAST(@row_count AS VARCHAR) + ' rows -> Silver.vle. (' + CAST(DATEDIFF(SECOND, @step_start, GETDATE()) AS VARCHAR) + 's)';


/* ===============================================================================
    STEP 3: Silver.assessments
    - Fills missing dates using module_presentation_length from Silver.courses.
    - Derives semester and is_final_exam flag.
    - Dependency: Silver.courses (Step 1).
=============================================================================== */
        SET @step_start = GETDATE();
        TRUNCATE TABLE Silver.assessments;

        INSERT INTO Silver.assessments (
            id_assessment, code_module, code_presentation,
            assessment_type, [date], [weight],
            semester, is_final_exam, load_timestamp
        )
        SELECT 
            TRIM(REPLACE(A.id_assessment,     '"', '')),
            TRIM(REPLACE(A.code_module,       '"', '')),
            TRIM(REPLACE(A.code_presentation, '"', '')),
            TRIM(REPLACE(A.assessment_type,   '"', '')),
            CASE 
                WHEN TRIM(REPLACE(A.[date], '"', '')) IN ('?', '') 
                  OR A.[date] IS NULL 
                THEN C.module_presentation_length 
                ELSE TRIM(REPLACE(A.[date], '"', '')) 
            END,
            TRIM(REPLACE(A.[weight], '"', '')),
            CASE 
                WHEN TRIM(REPLACE(A.code_presentation, '"', '')) LIKE '%B' THEN 'Spring'
                WHEN TRIM(REPLACE(A.code_presentation, '"', '')) LIKE '%J' THEN 'Autumn'
                ELSE 'Unknown'
            END,
            CASE WHEN TRIM(REPLACE(A.assessment_type, '"', '')) = 'Exam' THEN 1 ELSE 0 END,
            GETDATE()
        FROM Bronze.assessments A
        LEFT JOIN Silver.courses C 
            ON  TRIM(REPLACE(A.code_module,       '"', '')) = C.code_module 
            AND TRIM(REPLACE(A.code_presentation, '"', '')) = C.code_presentation;

        SET @row_count = @@ROWCOUNT;
        SET @total_rows += @row_count;
        PRINT 'STEP 3 SUCCESS: ' + CAST(@row_count AS VARCHAR) + ' rows -> Silver.assessments. (' + CAST(DATEDIFF(SECOND, @step_start, GETDATE()) AS VARCHAR) + 's)';


/* ===============================================================================
    STEP 4: Silver.studentInfo
    - Hierarchical imputation for imd_band:
        Level 1: Mode of (Region + Education + Age).
        Level 2: Mode of (Region) only as fallback.
=============================================================================== */
        SET @step_start = GETDATE();
        TRUNCATE TABLE Silver.studentInfo;

        WITH CleanedData AS (
            SELECT
                TRIM(REPLACE(region,            '"', '')) AS region,
                TRIM(REPLACE(highest_education, '"', '')) AS edu,
                TRIM(REPLACE(age_band,          '"', '')) AS age,
                TRIM(REPLACE(imd_band,          '"', '')) AS imd
            FROM Bronze.studentInfo
            WHERE TRIM(REPLACE(imd_band, '"', '')) NOT IN ('?', '')
              AND imd_band IS NOT NULL
        ),
        SpecificCounts AS (
            SELECT region, edu, age, imd, COUNT(*) AS freq
            FROM CleanedData
            GROUP BY region, edu, age, imd
        ),
        SpecificMap AS (
            SELECT region, edu, age, imd,
                   ROW_NUMBER() OVER (
                       PARTITION BY region, edu, age
                       ORDER BY freq DESC
                   ) AS rank_id
            FROM SpecificCounts
        ),
        FallbackCounts AS (
            SELECT region, imd, COUNT(*) AS freq
            FROM CleanedData
            GROUP BY region, imd
        ),
        FallbackMap AS (
            SELECT region, imd,
                   ROW_NUMBER() OVER (
                       PARTITION BY region
                       ORDER BY freq DESC
                   ) AS rank_id
            FROM FallbackCounts
        )
        INSERT INTO Silver.studentInfo (
            code_module, code_presentation, id_student,
            gender, region, highest_education, imd_band,
            age_band, num_of_prev_attempts, studied_credits,
            disability, final_result, load_timestamp
        )
        SELECT 
            TRIM(REPLACE(B.code_module,             '"', '')),
            TRIM(REPLACE(B.code_presentation,       '"', '')),
            TRIM(REPLACE(B.id_student,              '"', '')),
            TRIM(REPLACE(B.gender,                  '"', '')),
            TRIM(REPLACE(B.region,                  '"', '')),
            TRIM(REPLACE(B.highest_education,       '"', '')),
            -- Hierarchical Logic: Original -> Level 1 -> Level 2 (Fallback)
            CASE 
                WHEN TRIM(REPLACE(B.imd_band, '"', '')) NOT IN ('?', '')
                     AND B.imd_band IS NOT NULL 
                     THEN TRIM(REPLACE(B.imd_band, '"', ''))
                WHEN S.imd IS NOT NULL THEN S.imd
                ELSE F.imd
            END,
            TRIM(REPLACE(B.age_band,                '"', '')),
            TRIM(REPLACE(B.num_of_prev_attempts,    '"', '')),
            TRIM(REPLACE(B.studied_credits,         '"', '')),
            TRIM(REPLACE(B.disability,              '"', '')),
            TRIM(REPLACE(B.final_result,            '"', '')),
            GETDATE()
        FROM Bronze.studentInfo B
        LEFT JOIN SpecificMap S 
            ON  TRIM(REPLACE(B.region,              '"', '')) = S.region 
            AND TRIM(REPLACE(B.highest_education,   '"', '')) = S.edu 
            AND TRIM(REPLACE(B.age_band,            '"', '')) = S.age
            AND S.rank_id = 1
        LEFT JOIN FallbackMap F 
            ON  TRIM(REPLACE(B.region,              '"', '')) = F.region 
            AND F.rank_id = 1;

        SET @row_count = @@ROWCOUNT;
        SET @total_rows += @row_count;
        PRINT 'STEP 4 SUCCESS: ' + CAST(@row_count AS VARCHAR) + ' rows -> Silver.studentInfo. (' + CAST(DATEDIFF(SECOND, @step_start, GETDATE()) AS VARCHAR) + 's)';


/* ===============================================================================
    STEP 5: Silver.studentVle
    - Casts all fields to correct data types.
    - Retains all click values including outliers.
=============================================================================== */
        SET @step_start = GETDATE();
        TRUNCATE TABLE Silver.studentVle;

        INSERT INTO Silver.studentVle (
            code_module, code_presentation, id_student,
            id_site, [date], sum_click, load_timestamp
        )
        SELECT 
            TRIM(REPLACE(code_module,       '"', '')),
            TRIM(REPLACE(code_presentation, '"', '')),
            TRY_CAST(TRIM(REPLACE(id_student,      '"', '')) AS INT),
            TRY_CAST(TRIM(REPLACE(id_site,         '"', '')) AS INT),
            TRY_CAST(TRIM(REPLACE(studentVle_date, '"', '')) AS INT),
            TRY_CAST(TRIM(REPLACE(sum_click,       '"', '')) AS INT),
            GETDATE()
        FROM Bronze.studentVle;

        SET @row_count = @@ROWCOUNT;
        SET @total_rows += @row_count;
        PRINT 'STEP 5 SUCCESS: ' + CAST(@row_count AS VARCHAR) + ' rows -> Silver.studentVle. (' + CAST(DATEDIFF(SECOND, @step_start, GETDATE()) AS VARCHAR) + 's)';


/* ===============================================================================
    STEP 6: Silver.studentAssessment
    - Missing scores mapped to 0 (penalize missing submissions).
    - Derives weighted_score and is_late_submission.
    - Dependency: Silver.assessments (Step 3).
=============================================================================== */
        SET @step_start = GETDATE();
        TRUNCATE TABLE Silver.studentAssessment;

        INSERT INTO Silver.studentAssessment (
            id_assessment, id_student, date_submitted,
            is_banked, score, weighted_score,
            is_late_submission, load_timestamp
        )
        SELECT 
            TRIM(REPLACE(SA.id_assessment,  '"', '')),
            TRIM(REPLACE(SA.id_student,     '"', '')),
            TRIM(REPLACE(SA.date_submitted, '"', '')),
            TRIM(REPLACE(SA.is_banked,      '"', '')),
            CASE WHEN TRIM(REPLACE(SA.score, '"', '')) = '?' THEN 0 
                 ELSE TRY_CAST(TRIM(REPLACE(SA.score, '"', '')) AS FLOAT) 
            END,
            (CASE WHEN TRIM(REPLACE(SA.score, '"', '')) = '?' THEN 0 
                  ELSE TRY_CAST(TRIM(REPLACE(SA.score, '"', '')) AS FLOAT) 
             END * A.[weight]) / 100,
            CASE WHEN TRY_CAST(TRIM(REPLACE(SA.date_submitted, '"', '')) AS INT) > A.[date] 
                 THEN 1 ELSE 0 
            END,
            GETDATE()
        FROM Bronze.studentAssessment SA
        LEFT JOIN Silver.assessments A 
            ON TRIM(REPLACE(SA.id_assessment, '"', '')) = A.id_assessment;

        SET @row_count = @@ROWCOUNT;
        SET @total_rows += @row_count;
        PRINT 'STEP 6 SUCCESS: ' + CAST(@row_count AS VARCHAR) + ' rows -> Silver.studentAssessment. (' + CAST(DATEDIFF(SECOND, @step_start, GETDATE()) AS VARCHAR) + 's)';


/* ===============================================================================
    STEP 7: Silver.studentRegistration
    - Imputes missing reg dates from Silver.studentVle (first click).
    - Non-withdrawn students get course_length as exit date proxy.
    - Resolves unreg < reg logical errors.
    - Dependency: Silver.studentInfo (Step 4), Silver.studentVle (Step 5).
=============================================================================== */
        SET @step_start = GETDATE();
        TRUNCATE TABLE Silver.studentRegistration;

        WITH FirstVleInteraction AS (
            SELECT 
                id_student, code_module, code_presentation,
                MIN([date]) AS first_click
            FROM Silver.studentVle
            GROUP BY id_student, code_module, code_presentation
        ),
        CleanedSource AS (
            SELECT 
                TRIM(REPLACE(R.code_module,         '"', '')) AS module,
                TRIM(REPLACE(R.code_presentation,   '"', '')) AS presentation,
                TRIM(REPLACE(R.id_student,          '"', '')) AS student_id,
                TRY_CAST(TRIM(REPLACE(R.date_registration,   '"', '')) AS INT) AS raw_reg_date,
                TRY_CAST(TRIM(REPLACE(R.date_unregistration, '"', '')) AS INT) AS raw_unreg_date,
                SI.final_result                              AS final_res,
                C.module_presentation_length                 AS course_len
            FROM Bronze.studentRegistration R
            LEFT JOIN Silver.studentInfo SI 
                ON  TRIM(REPLACE(R.code_module,       '"', '')) = SI.code_module 
                AND TRIM(REPLACE(R.code_presentation, '"', '')) = SI.code_presentation 
                AND TRIM(REPLACE(R.id_student,        '"', '')) = SI.id_student
            LEFT JOIN Silver.courses C 
                ON  TRIM(REPLACE(R.code_module,       '"', '')) = C.code_module 
                AND TRIM(REPLACE(R.code_presentation, '"', '')) = C.code_presentation
        )
        INSERT INTO Silver.studentRegistration (
            code_module, code_presentation, id_student,
            date_registration, date_unregistration,
            is_active, days_enrolled, is_imputed
        )
        SELECT 
            CS.module,
            CS.presentation,
            CS.student_id,
            COALESCE(CS.raw_reg_date, V.first_click, 0),
            -- Withdrawn with valid unreg_date → use it. Otherwise → course length proxy
            CASE 
                WHEN CS.final_res = 'Withdrawn' 
                     AND CS.raw_unreg_date >= COALESCE(CS.raw_reg_date, V.first_click, 0) 
                THEN CS.raw_unreg_date
                ELSE CS.course_len 
            END,
            CASE WHEN CS.final_res = 'Withdrawn' THEN 0 ELSE 1 END,
            -- Withdrawn → actual duration. Others → full course length
            CASE 
                WHEN CS.final_res = 'Withdrawn' 
                     AND CS.raw_unreg_date >= COALESCE(CS.raw_reg_date, V.first_click, 0)
                THEN CS.raw_unreg_date - COALESCE(CS.raw_reg_date, V.first_click, 0)
                ELSE CS.course_len 
            END,
            CASE WHEN CS.raw_reg_date IS NULL THEN 1 ELSE 0 END
        FROM CleanedSource CS
        LEFT JOIN FirstVleInteraction V 
            ON  CS.student_id   = CAST(V.id_student AS VARCHAR)
            AND CS.module       = V.code_module
            AND CS.presentation = V.code_presentation;

        SET @row_count = @@ROWCOUNT;
        SET @total_rows += @row_count;
        PRINT 'STEP 7 SUCCESS: ' + CAST(@row_count AS VARCHAR) + ' rows -> Silver.studentRegistration. (' + CAST(DATEDIFF(SECOND, @step_start, GETDATE()) AS VARCHAR) + 's)';


/* ===============================================================================
    MASTER SUMMARY
=============================================================================== */
        PRINT '';
        PRINT '##################################################';
        PRINT '# MASTER LOAD COMPLETE                          #';
        PRINT '# Total Rows Loaded : ' + CAST(@total_rows AS VARCHAR);
        PRINT '# Total Duration    : ' + CAST(DATEDIFF(SECOND, @start_time, GETDATE()) AS VARCHAR) + ' seconds';
        PRINT '##################################################';

    END TRY
    BEGIN CATCH
        PRINT '';
        PRINT '##################################################';
        PRINT '# MASTER LOAD FAILED                            #';
        PRINT '# Error: ' + ERROR_MESSAGE();
        PRINT '##################################################';
    END CATCH
END;
GO

-- Active
EXEC Silver.load_Silver;
GO