-- ==============================================================================
-- EPILEPSY CLINICAL DATA WAREHOUSE: INDEXES & PERFORMANCE TUNING
-- Database Engine: MySQL 8.0+
-- File: sql/05_indexes_performance.sql
-- Description: B-Tree index specifications, execution plan diagnostics using
--              EXPLAIN ANALYZE, and table partitioning strategies.
-- ==============================================================================

USE epilepsy_dw;

-- ==============================================================================
-- PART 1: Index Creation for Query Optimization
-- Purpose: Accelerate JOINs, filtering, and window function PARTITION BY operations.
-- Recruiter Signal: Demonstrates database indexing best practices to optimize I/O.
-- ==============================================================================

-- 1. Patients Table: Optimizes demographic filtering & range scans
CREATE INDEX idx_patients_age_gender 
ON patients(age, gender);

-- 2. Encounters Table: Optimizes time-series joins, readmission calculations, & window partitioning
CREATE INDEX idx_encounters_patient_date 
ON encounters(patient_id, encounter_date);

CREATE INDEX idx_encounters_type_date 
ON encounters(encounter_type, encounter_date);

-- 3. Diagnoses Table: Optimizes grouping and filtering by epilepsy classification
CREATE INDEX idx_diagnoses_epilepsy_type 
ON diagnoses(epilepsy_type);

-- 4. Diagnostic Results Table: Optimizes filtering on abnormal MRI/CT imaging results
CREATE INDEX idx_eeg_mri_encounter_result 
ON eeg_mri_results(encounter_id, mri_ct_result);

-- 5. Prescriptions Table: Optimizes non-adherence and medication status lookups
CREATE INDEX idx_prescriptions_status_missed 
ON prescriptions(medication_status, missed_medication);


-- ==============================================================================
-- PART 2: Query Execution Plan Diagnostics (`EXPLAIN ANALYZE`)
-- Purpose: Inspect join strategies, index coverage, and cost estimates.
-- Recruiter Signal: Shows ability to identify performance bottlenecks in MySQL.
-- ==============================================================================

-- Diagnostic Query 1: Inspect Readmission CTE Execution Plan
EXPLAIN ANALYZE
SELECT 
    e.patient_id,
    e.encounter_date,
    LEAD(e.encounter_date) OVER(PARTITION BY e.patient_id ORDER BY e.encounter_date) AS next_visit
FROM encounters e
WHERE e.encounter_type IN ('Inpatient', 'Emergency');

-- Diagnostic Query 2: Inspect Multi-Table Join Strategy for High-Risk Cohort Isolation
EXPLAIN ANALYZE
SELECT 
    p.patient_id,
    p.age,
    d.epilepsy_type,
    eeg.mri_ct_result
FROM patients p
INNER JOIN diagnoses d ON p.patient_id = d.patient_id
INNER JOIN eeg_mri_results eeg ON d.encounter_id = eeg.encounter_id
WHERE eeg.mri_ct_result = 'Abnormal' AND p.age >= 50;


-- ==============================================================================
-- PART 3: Table Partitioning Strategy (Architectural Scalability Guidance)
-- Purpose: Partition large event-level tables (e.g., encounters) by date ranges.
-- Recruiter Signal: Demonstrates architectural foresight for scaling to millions of rows.
-- ==============================================================================

/*
-- RANGE Partitioning Example for Encounters Table (Production Blueprint):

ALTER TABLE encounters 
PARTITION BY RANGE (YEAR(encounter_date)) (
    PARTITION p_2023 VALUES LESS THAN (2024),
    PARTITION p_2024 VALUES LESS THAN (2025),
    PARTITION p_2025 VALUES LESS THAN (2026),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);
*/
