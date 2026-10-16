-- ==============================================================================
-- EPILEPSY CLINICAL DATA WAREHOUSE: QA & VALIDATION SUITE
-- Database Engine: MySQL 8.0+
-- File: sql/04_qa_validation_tests.sql
-- Description: Automated data validation, referential integrity assertions,
--              duplicate checking, and clinical anomaly detection queries.
-- ==============================================================================

USE epilepsy_dw;

-- ==============================================================================
-- TEST 1: Table Row Count Assertions
-- Purpose: Verify all target tables contain the expected row counts post-ETL.
-- Recruiter Signal: Demonstrates automated pipeline verification and monitoring.
-- ==============================================================================
SELECT 'patients' AS entity_name, COUNT(*) AS total_rows, CASE WHEN COUNT(*) = 4856 THEN 'PASS' ELSE 'FAIL' END AS QA_Status FROM patients
UNION ALL
SELECT 'encounters', COUNT(*), CASE WHEN COUNT(*) = 4856 THEN 'PASS' ELSE 'FAIL' END FROM encounters
UNION ALL
SELECT 'diagnoses', COUNT(*), CASE WHEN COUNT(*) = 4856 THEN 'PASS' ELSE 'FAIL' END FROM diagnoses
UNION ALL
SELECT 'medical_histories', COUNT(*), CASE WHEN COUNT(*) = 4856 THEN 'PASS' ELSE 'FAIL' END FROM medical_histories
UNION ALL
SELECT 'eeg_mri_results', COUNT(*), CASE WHEN COUNT(*) = 4856 THEN 'PASS' ELSE 'FAIL' END FROM eeg_mri_results
UNION ALL
SELECT 'lifestyle_triggers', COUNT(*), CASE WHEN COUNT(*) = 4856 THEN 'PASS' ELSE 'FAIL' END FROM lifestyle_triggers
UNION ALL
SELECT 'prescriptions', COUNT(*), CASE WHEN COUNT(*) = 4856 THEN 'PASS' ELSE 'FAIL' END FROM prescriptions;


-- ==============================================================================
-- TEST 2: Null Value Integrity Audit across Primary & Foreign Keys
-- Purpose: Confirm zero key columns contain NULL values.
-- Recruiter Signal: Enforces strict data governance and relational constraints.
-- ==============================================================================
SELECT 
    SUM(CASE WHEN patient_id IS NULL THEN 1 ELSE 0 END) AS null_patients_pk,
    SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END) AS null_patient_age,
    SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END) AS null_patient_gender
FROM patients;

SELECT 
    SUM(CASE WHEN encounter_id IS NULL THEN 1 ELSE 0 END) AS null_encounters_pk,
    SUM(CASE WHEN patient_id IS NULL THEN 1 ELSE 0 END) AS null_encounters_fk,
    SUM(CASE WHEN encounter_date IS NULL THEN 1 ELSE 0 END) AS null_encounter_date
FROM encounters;


-- ==============================================================================
-- TEST 3: Referential Integrity & Orphan Record Check
-- Purpose: Detect child table rows that fail to map to a valid master patient record.
-- Recruiter Signal: Validates relational consistency across entity relationships.
-- ==============================================================================
SELECT 
    'Orphan Encounters' AS test_description,
    COUNT(e.encounter_id) AS orphan_count
FROM encounters e
LEFT JOIN patients p ON e.patient_id = p.patient_id
WHERE p.patient_id IS NULL

UNION ALL

SELECT 
    'Orphan Diagnoses',
    COUNT(d.diagnosis_id)
FROM diagnoses d
LEFT JOIN encounters e ON d.encounter_id = e.encounter_id
WHERE e.encounter_id IS NULL;


-- ==============================================================================
-- TEST 4: Duplicate Record Detection
-- Purpose: Identify duplicate patient encounters logged on the same timestamp.
-- Recruiter Signal: Ensures unique event logging and prevents data duplication.
-- ==============================================================================
SELECT 
    patient_id, 
    encounter_date, 
    COUNT(*) AS occurrence_count
FROM encounters
GROUP BY patient_id, encounter_date
HAVING COUNT(*) > 1;


-- ==============================================================================
-- TEST 5: Outlier & Physiological Range Checks
-- Purpose: Flags clinically impossible metric values (e.g., negative or extreme vitals).
-- Recruiter Signal: Shows clinical domain awareness and data cleaning rigor.
-- ==============================================================================
SELECT 
    patient_id, 
    age, 
    height_cm, 
    weight_kg,
    'Invalid Demographic Range' AS QA_Flag
FROM patients
WHERE age < 0 OR age > 120
   OR height_cm < 30 OR height_cm > 250
   OR weight_kg < 2  OR weight_kg > 300;

SELECT 
    encounter_id, 
    seizure_duration_sec,
    'Extreme Seizure Duration' AS QA_Flag
FROM encounters
WHERE seizure_duration_sec < 0 OR seizure_duration_sec > 86400;


-- ==============================================================================
-- TEST 6: Unmapped / Categorical Value Drift Validation
-- Purpose: Identify unrecognized categorical entries in medical reports.
-- Recruiter Signal: Validates categorical consistency across domain metrics.
-- ==============================================================================
SELECT DISTINCT 
    epilepsy_type, 
    CASE 
        WHEN epilepsy_type IN ('Generalized', 'Focal', 'Absence', 'Complicated', 'Normal', 'Not Confirmed') THEN 'Valid'
        ELSE 'Invalid Category' 
    END AS category_status
FROM diagnoses;