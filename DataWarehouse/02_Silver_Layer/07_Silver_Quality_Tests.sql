/* ===============================================================================
Script: Silver Data Quality Verification
Description:
    Master quality report for all Silver layer tables after cleaning and loading.
    Runs structured checks per table and outputs a final summary.
    
    Execution Order:
        1. Silver.courses
        2. Silver.vle
        3. Silver.assessments
        4. Silver.studentInfo
        5. Silver.studentVle
        6. Silver.studentAssessment
        7. Silver.studentRegistration
BY\ Abdelrahman Ahmed
=============================================================================== */

DECLARE @total_issues INT = 0;
DECLARE @issues       INT = 0;

PRINT '##################################################';
PRINT '# SILVER LAYER — DATA QUALITY REPORT            #';
PRINT '# Run Time: ' + CONVERT(VARCHAR, GETDATE(), 120) + '           #';
PRINT '##################################################';


/* ===============================================================================
    TABLE 1: Silver.courses
=============================================================================== */
PRINT '';
PRINT '================================================';
PRINT 'TABLE 1 | Silver.courses';
PRINT '================================================';

SELECT
    'Unknown semester'                  AS test_name,
    COUNT(*)                            AS problem_count,
    'Should be 0'                       AS expected
FROM Silver.courses WHERE semester = 'Unknown'
UNION ALL
SELECT
    'NULL module length',
    COUNT(*),
    'Should be 0'
FROM Silver.courses WHERE module_presentation_length IS NULL
UNION ALL
SELECT
    'Zero or negative module length',
    COUNT(*),
    'Should be 0'
FROM Silver.courses WHERE module_presentation_length <= 0
UNION ALL
SELECT
    'Double quotes presence (Bronze check)',
    COUNT(*),
    'Should be 0'
FROM Bronze.courses WHERE code_module LIKE '%"%' OR code_presentation LIKE '%"%';

-- Row count summary
SELECT 'Total rows loaded' AS info, COUNT(*) AS value FROM Silver.courses;


/* ===============================================================================
    TABLE 2: Silver.vle
=============================================================================== */
PRINT '';
PRINT '================================================';
PRINT 'TABLE 2 | Silver.vle';
PRINT '================================================';

SELECT
    'NULL id_site'                      AS test_name,
    COUNT(*)                            AS problem_count,
    'Should be 0'                       AS expected
FROM Silver.vle WHERE id_site IS NULL
UNION ALL
SELECT
    'NULL activity_type',
    COUNT(*),
    'Should be 0'
FROM Silver.vle WHERE activity_type IS NULL OR activity_type = ''
UNION ALL
SELECT
    'Negative week values',
    COUNT(*),
    'Should be 0'
FROM Silver.vle WHERE week_from < 0 OR week_to < 0
UNION ALL
SELECT
    'week_from > week_to (logical error)',
    COUNT(*),
    'Should be 0'
FROM Silver.vle WHERE week_from > week_to AND week_to <> 0;

-- Imputed weeks summary
PRINT '--- Imputed Week Values ---';
SELECT
    is_week_imputed                     AS imputed_flag,
    COUNT(*)                            AS total_rows
FROM Silver.vle
GROUP BY is_week_imputed;

SELECT 'Total rows loaded' AS info, COUNT(*) AS value FROM Silver.vle;


/* ===============================================================================
    TABLE 3: Silver.assessments
=============================================================================== */
PRINT '';
PRINT '================================================';
PRINT 'TABLE 3 | Silver.assessments';
PRINT '================================================';

SELECT
    'NULL assessment date'              AS test_name,
    COUNT(*)                            AS problem_count,
    'Should be 0'                       AS expected
FROM Silver.assessments WHERE [date] IS NULL
UNION ALL
SELECT
    'NULL weight',
    COUNT(*),
    'Should be 0'
FROM Silver.assessments WHERE [weight] IS NULL
UNION ALL
SELECT
    'Weight out of range (0-100)',
    COUNT(*),
    'Should be 0'
FROM Silver.assessments WHERE [weight] < 0 OR [weight] > 100
UNION ALL
SELECT
    'Unknown semester',
    COUNT(*),
    'Should be 0'
FROM Silver.assessments WHERE semester = 'Unknown'
UNION ALL
SELECT
    'Exam flagged incorrectly (is_final_exam=1 but not Exam type)',
    COUNT(*),
    'Should be 0'
FROM Silver.assessments WHERE is_final_exam = 1 AND assessment_type <> 'Exam';

-- Assessment type distribution
PRINT '--- Assessment Type Distribution ---';
SELECT assessment_type, COUNT(*) AS total FROM Silver.assessments GROUP BY assessment_type;

SELECT 'Total rows loaded' AS info, COUNT(*) AS value FROM Silver.assessments;


/* ===============================================================================
    TABLE 4: Silver.studentInfo
=============================================================================== */
PRINT '';
PRINT '================================================';
PRINT 'TABLE 4 | Silver.studentInfo';
PRINT '================================================';

SELECT
    'Missing imd_band after imputation'         AS test_name,
    COUNT(*)                                    AS problem_count,
    'Should be 0'                               AS expected
FROM Silver.studentInfo WHERE imd_band IS NULL OR imd_band IN ('?', '')
UNION ALL
SELECT
    'Invalid gender value',
    COUNT(*),
    'Should be 0'
FROM Silver.studentInfo WHERE gender NOT IN ('M', 'F')
UNION ALL
SELECT
    'Negative prev attempts',
    COUNT(*),
    'Should be 0'
FROM Silver.studentInfo WHERE num_of_prev_attempts < 0
UNION ALL
SELECT
    'Zero or negative studied credits',
    COUNT(*),
    'Should be 0'
FROM Silver.studentInfo WHERE studied_credits <= 0
UNION ALL
SELECT
    'Invalid disability flag',
    COUNT(*),
    'Should be 0'
FROM Silver.studentInfo WHERE disability NOT IN ('Y', 'N')
UNION ALL
SELECT
    'Invalid final result value',
    COUNT(*),
    'Should be 0'
FROM Silver.studentInfo
WHERE final_result NOT IN ('Pass', 'Fail', 'Withdrawn', 'Distinction');

-- imd_band distribution
PRINT '--- IMD Band Distribution ---';
SELECT imd_band, COUNT(*) AS total FROM Silver.studentInfo GROUP BY imd_band ORDER BY imd_band;

-- Final result distribution
PRINT '--- Final Result Distribution ---';
SELECT final_result, COUNT(*) AS total FROM Silver.studentInfo GROUP BY final_result;

SELECT 'Total rows loaded' AS info, COUNT(*) AS value FROM Silver.studentInfo;


/* ===============================================================================
    TABLE 5: Silver.studentVle
=============================================================================== */
PRINT '';
PRINT '================================================';
PRINT 'TABLE 5 | Silver.studentVle';
PRINT '================================================';

SELECT
    'NULL student ID'                   AS test_name,
    COUNT(*)                            AS problem_count,
    'Should be 0'                       AS expected
FROM Silver.studentVle WHERE id_student IS NULL
UNION ALL
SELECT
    'NULL site ID',
    COUNT(*),
    'Should be 0'
FROM Silver.studentVle WHERE id_site IS NULL
UNION ALL
SELECT
    'NULL interaction date',
    COUNT(*),
    'Should be 0'
FROM Silver.studentVle WHERE [date] IS NULL
UNION ALL
SELECT
    'Negative or zero click count',
    COUNT(*),
    'Informational — review outliers'
FROM Silver.studentVle WHERE sum_click <= 0;

-- Click count outlier summary
PRINT '--- Click Count Distribution (Outlier Check) ---';
SELECT
    MIN(sum_click)      AS min_clicks,
    MAX(sum_click)      AS max_clicks,
    AVG(sum_click)      AS avg_clicks,
    COUNT(*)            AS total_rows
FROM Silver.studentVle;

SELECT 'Total rows loaded' AS info, COUNT(*) AS value FROM Silver.studentVle;


/* ===============================================================================
    TABLE 6: Silver.studentAssessment
=============================================================================== */
PRINT '';
PRINT '================================================';
PRINT 'TABLE 6 | Silver.studentAssessment';
PRINT '================================================';

SELECT
    'Score out of range (0-100)'        AS test_name,
    COUNT(*)                            AS problem_count,
    'Should be 0'                       AS expected
FROM Silver.studentAssessment WHERE score < 0 OR score > 100
UNION ALL
SELECT
    'Negative weighted score',
    COUNT(*),
    'Should be 0'
FROM Silver.studentAssessment WHERE weighted_score < 0
UNION ALL
SELECT
    'NULL submission date',
    COUNT(*),
    'Should be 0'
FROM Silver.studentAssessment WHERE date_submitted IS NULL
UNION ALL
SELECT
    'Orphaned assessment (no match in Silver.assessments)',
    COUNT(*),
    'Should be 0'
FROM Silver.studentAssessment SA
WHERE NOT EXISTS (
    SELECT 1 FROM Silver.assessments A WHERE A.id_assessment = SA.id_assessment
);

-- Imputed score summary (score = 0 may be imputed)
PRINT '--- Score = 0 Count (Imputed Missing Scores) ---';
SELECT 'Rows with score = 0' AS info, COUNT(*) AS total FROM Silver.studentAssessment WHERE score = 0;

-- Late submission summary
PRINT '--- Late Submission Summary ---';
SELECT
    is_late_submission,
    COUNT(*) AS total
FROM Silver.studentAssessment
GROUP BY is_late_submission;

SELECT 'Total rows loaded' AS info, COUNT(*) AS value FROM Silver.studentAssessment;


/* ===============================================================================
    TABLE 7: Silver.studentRegistration
=============================================================================== */
PRINT '';
PRINT '================================================';
PRINT 'TABLE 7 | Silver.studentRegistration';
PRINT '================================================';

SELECT
    'Logical error: unreg before reg'               AS test_name,
    COUNT(*)                                        AS problem_count,
    'Should be 0'                                   AS expected
FROM Silver.studentRegistration
WHERE date_unregistration < date_registration
UNION ALL
SELECT
    'Missing registration date',
    COUNT(*),
    'Should be 0'
FROM Silver.studentRegistration WHERE date_registration IS NULL
UNION ALL
SELECT
    'Active student with unregistration date',
    COUNT(*),
    'Should be 0'
FROM Silver.studentRegistration WHERE is_active = 1 AND date_unregistration IS NOT NULL
UNION ALL
SELECT
    'Withdrawn student missing unregistration date',
    COUNT(*),
    'Informational — some may be valid'
FROM Silver.studentRegistration WHERE is_active = 0 AND date_unregistration IS NULL
UNION ALL
SELECT
    'Negative days enrolled',
    COUNT(*),
    'Should be 0'
FROM Silver.studentRegistration WHERE days_enrolled < 0
UNION ALL
SELECT
    'Orphaned student (no match in Silver.studentInfo)',
    COUNT(*),
    'Should be 0'
FROM Silver.studentRegistration SR
WHERE NOT EXISTS (
    SELECT 1 FROM Silver.studentInfo SI
    WHERE SI.id_student = SR.id_student
      AND SI.code_module = SR.code_module
      AND SI.code_presentation = SR.code_presentation
);

-- Imputed registrations sample
PRINT '--- Sample of Imputed Records (From VLE Source) ---';
SELECT TOP 10 * FROM Silver.studentRegistration WHERE is_imputed = 1;

-- Enrollment status summary
PRINT '--- Final Enrollment Status Summary ---';
SELECT
    CASE WHEN is_active = 1 THEN 'Active / Passed / Failed' ELSE 'Withdrawn' END AS status,
    COUNT(*) AS total_students
FROM Silver.studentRegistration
GROUP BY is_active;

SELECT 'Total rows loaded' AS info, COUNT(*) AS value FROM Silver.studentRegistration;


/* ===============================================================================
    MASTER SUMMARY
=============================================================================== */
PRINT '';
PRINT '##################################################';
PRINT '# QUALITY REPORT COMPLETE                       #';
PRINT '# Review any problem_count > 0 above            #';
PRINT '# Informational checks do not indicate failures #';
PRINT '##################################################';