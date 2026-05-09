/* ===============================================================================
Script: Gold Layer — Final Data Quality & Verification
Description: Corrected version to match the updated semantic table names.

BY\ Abdelrahman Ahmed
=============================================================================== */

PRINT '##################################################';
PRINT '# GOLD LAYER — SEMANTIC QUALITY REPORT           #';
PRINT '##################################################';

/* --- 1. Check: Dim_Modules_Catalog --- */
PRINT 'Checking Gold.Dim_Modules_Catalog...';
SELECT 'NULL Module_Key' AS Test, COUNT(*) AS Problems FROM Gold.Dim_Modules_Catalog WHERE Module_Key IS NULL
UNION ALL
SELECT 'Unknown Semester', COUNT(*) FROM Gold.Dim_Modules_Catalog WHERE semester = 'Unknown';

/* --- 2. Check: Dim_Assessments_Info --- */
PRINT 'Checking Gold.Dim_Assessments_Info...';
SELECT 'Orphaned Module_Key' AS Test, COUNT(*) AS Problems 
FROM Gold.Dim_Assessments_Info A WHERE NOT EXISTS (SELECT 1 FROM Gold.Dim_Modules_Catalog M WHERE M.Module_Key = A.Module_Key);

/* --- 3. Check: Dim_Students_Profile --- */
PRINT 'Checking Gold.Dim_Students_Profile...';
SELECT 'Missing IMD Band' AS Test, COUNT(*) AS Problems FROM Gold.Dim_Students_Profile WHERE imd_band IS NULL OR imd_band = '';

/* --- 4. Check: Dim_Vle_Resources --- */
PRINT 'Checking Gold.Dim_Vle_Resources...';
SELECT 'Logical Error (WeekFrom > WeekTo)' AS Test, COUNT(*) AS Problems FROM Gold.Dim_Vle_Resources WHERE week_from > week_to AND week_to <> 0;

/* --- 5. Check: Fact_Enrollment --- */
PRINT 'Checking Gold.Fact_Enrollment...';
SELECT 'Target Variable Missing' AS Test, COUNT(*) AS Problems FROM Gold.Fact_Enrollment WHERE final_result IS NULL;

/* --- 6. Check: Fact_Student_Scores --- */
PRINT 'Checking Gold.Fact_Student_Scores...';
SELECT 'Score Out of Range' AS Test, COUNT(*) AS Problems FROM Gold.Fact_Student_Scores WHERE score < 0 OR score > 100;

/* --- 7. Check: Fact_Student_Vle_Clicks --- */
PRINT 'Checking Gold.Fact_Student_Vle_Clicks...';
SELECT 'NULL Click Records' AS Test, COUNT(*) AS Problems FROM Gold.Fact_Student_Vle_Clicks WHERE sum_click IS NULL;

-- Final Summary of Rows
PRINT '--- Row Count Summary ---';
SELECT 'Modules' as Tbl, COUNT(*) FROM Gold.Dim_Modules_Catalog UNION ALL
SELECT 'Students', COUNT(*) FROM Gold.Dim_Students_Profile UNION ALL
SELECT 'Enrollments', COUNT(*) FROM Gold.Fact_Enrollment UNION ALL
SELECT 'VLE Interactions', COUNT(*) FROM Gold.Fact_Student_Vle_Clicks;