-- ==============================================================================
-- EPILEPSY CLINICAL DATA WAREHOUSE: CORE ANALYTICS PIPELINE
-- Database Engine: MySQL 8.0+
-- File: sql/03_core_analytics.sql
-- Description: Advanced analytical queries demonstrating CTEs, Window Functions,
--              30-day readmission tracking, time-series intervals, and risk scoring.
-- ==============================================================================

USE epilepsy_dw;

-- ==============================================================================
-- QUERY 1: Basic Cohort Selection
-- Purpose: Isolate adult patients (18–65) with active seizures on medication.
-- Recruiter Signal: Demonstrates clean join logic and precise clinical cohort filtering.
-- ==============================================================================
SELECT 
    p.patient_id,
    p.age,
    p.gender,
    e.seizure_frequency,
    e.seizure_type,
    pr.medication_status
FROM patients p
INNER JOIN encounters e ON p.patient_id = e.patient_id
INNER JOIN prescriptions pr ON e.encounter_id = pr.encounter_id
WHERE p.age BETWEEN 18 AND 65
  AND e.seizure_frequency >= 1
  AND pr.medication_status = 'On Medication'
ORDER BY e.seizure_frequency DESC, p.age ASC;


-- ==============================================================================
-- QUERY 2: Demographics and Summary Statistics
-- Purpose: Summarize patient demographics and total clinical encounters grouped by age bands.
-- Recruiter Signal: Demonstrates mathematical floor binning and multi-dimensional aggregation.
-- ==============================================================================
SELECT 
    p.gender,
    CONCAT(FLOOR(p.age / 10) * 10, '-', FLOOR(p.age / 10) * 10 + 9) AS age_bracket,
    COUNT(DISTINCT p.patient_id) AS total_patients,
    COUNT(e.encounter_id) AS total_encounters,
    ROUND(AVG(p.weight_kg), 2) AS avg_weight_kg,
    ROUND(AVG(e.seizure_duration_sec), 1) AS avg_seizure_duration_sec
FROM patients p
LEFT JOIN encounters e ON p.patient_id = e.patient_id
GROUP BY p.gender, age_bracket
ORDER BY age_bracket ASC, p.gender;


-- ==============================================================================
-- QUERY 3: Diagnosis Prevalence & Comorbidity Matrix
-- Purpose: Compute the prevalence of key neurological risk factors per epilepsy type.
-- Recruiter Signal: Uses conditional aggregation (CASE WHEN inside SUM) for pivot reporting.
-- ==============================================================================
SELECT 
    d.epilepsy_type,
    COUNT(DISTINCT d.patient_id) AS total_cases,
    SUM(CASE WHEN mh.head_injury = 'Yes' THEN 1 ELSE 0 END) AS head_injury_cases,
    SUM(CASE WHEN mh.stroke_history = 'Yes' THEN 1 ELSE 0 END) AS stroke_cases,
    SUM(CASE WHEN mh.brain_tumor = 'Yes' THEN 1 ELSE 0 END) AS brain_tumor_cases,
    ROUND(SUM(CASE WHEN mh.stroke_history = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT d.patient_id), 2) AS stroke_prevalence_pct
FROM diagnoses d
INNER JOIN medical_histories mh ON d.patient_id = mh.patient_id
GROUP BY d.epilepsy_type
ORDER BY total_cases DESC;


-- ==============================================================================
-- QUERY 4: 30-Day Hospital Readmission Rate Analysis
-- Purpose: Track inpatient/emergency readmissions occurring within 30 days of discharge.
-- Recruiter Signal: Advanced window function logic (LEAD) for healthcare quality reporting.
-- ==============================================================================
WITH RankedEncounters AS (
    SELECT 
        patient_id,
        encounter_id,
        encounter_date,
        LEAD(encounter_date) OVER(
            PARTITION BY patient_id 
            ORDER BY encounter_date
        ) AS next_admission_date
    FROM encounters
    WHERE encounter_type IN ('Inpatient', 'Emergency')
),
ReadmissionCalc AS (
    SELECT 
        patient_id,
        encounter_id,
        encounter_date,
        next_admission_date,
        DATEDIFF(next_admission_date, encounter_date) AS days_to_readmit,
        CASE 
            WHEN DATEDIFF(next_admission_date, encounter_date) BETWEEN 1 AND 30 THEN 1 
            ELSE 0 
        END AS readmitted_30d
    FROM RankedEncounters
    WHERE next_admission_date IS NOT NULL
)
SELECT 
    COUNT(encounter_id) AS total_index_encounters,
    SUM(readmitted_30d) AS total_30d_readmissions,
    ROUND((SUM(readmitted_30d) / COUNT(encounter_id)) * 100, 2) AS readmission_rate_pct
FROM ReadmissionCalc;


-- ==============================================================================
-- QUERY 5: Statistical Distribution Analysis (Median & IQR Proxy)
-- Purpose: Calculate Length of Stay (LOS) statistical distribution metrics using windowing.
-- Recruiter Signal: Shows ability to compute non-trivial summary statistics (Percentiles) in MySQL.
-- ==============================================================================
WITH StayDurations AS (
    SELECT 
        encounter_id,
        seizure_duration_sec / 60.0 AS duration_minutes,
        ROW_NUMBER() OVER (ORDER BY seizure_duration_sec) AS row_num,
        COUNT(*) OVER () AS total_count
    FROM encounters
)
SELECT 
    ROUND(AVG(duration_minutes), 2) AS mean_duration_min,
    ROUND(MAX(CASE WHEN row_num = FLOOR(total_count * 0.25) THEN duration_minutes END), 2) AS p25_duration_min,
    ROUND(MAX(CASE WHEN row_num = FLOOR(total_count * 0.50) THEN duration_minutes END), 2) AS median_duration_min,
    ROUND(MAX(CASE WHEN row_num = FLOOR(total_count * 0.75) THEN duration_minutes END), 2) AS p75_duration_min
FROM StayDurations;


-- ==============================================================================
-- QUERY 6: Time-to-Event Interval Analytics
-- Purpose: Measure elapsed days between consecutive seizure encounters per patient.
-- Recruiter Signal: Uses LAG() window function for event sequencing and trend analysis.
-- ==============================================================================
SELECT 
    patient_id,
    encounter_id,
    encounter_date,
    LAG(encounter_date) OVER (
        PARTITION BY patient_id 
        ORDER BY encounter_date
    ) AS prior_encounter_date,
    DATEDIFF(
        encounter_date, 
        LAG(encounter_date) OVER (PARTITION BY patient_id ORDER BY encounter_date)
    ) AS days_between_encounters
FROM encounters
WHERE seizure_frequency > 0
ORDER BY patient_id, encounter_date;


-- ==============================================================================
-- QUERY 7: Diagnostic Signal Rolling Trend Analysis
-- Purpose: Compute 3-encounter rolling averages for seizure frequency metrics.
-- Recruiter Signal: Advanced window framing (ROWS BETWEEN PRECEDING AND CURRENT ROW).
-- ==============================================================================
SELECT 
    patient_id,
    encounter_id,
    seizure_frequency,
    ROUND(
        AVG(seizure_frequency) OVER (
            PARTITION BY patient_id 
            ORDER BY encounter_id 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    ) AS rolling_3encounter_avg_frequency
FROM encounters;


-- ==============================================================================
-- QUERY 8: Medication Adherence & Compliance Gap Profiling
-- Purpose: Identify patients non-adherent to anti-epileptic medication regiments.
-- Recruiter Signal: Translates pharmacy non-compliance indicators into operational risk metrics.
-- ==============================================================================
SELECT 
    p.patient_id,
    p.age,
    rx.medication_status,
    rx.missed_medication,
    COUNT(e.encounter_id) AS total_encounters,
    AVG(e.seizure_frequency) AS avg_seizure_frequency
FROM patients p
INNER JOIN encounters e ON p.patient_id = e.patient_id
INNER JOIN prescriptions rx ON e.encounter_id = rx.encounter_id
WHERE rx.missed_medication = 'Yes'
GROUP BY p.patient_id, p.age, rx.medication_status, rx.missed_medication
ORDER BY avg_seizure_frequency DESC;


-- ==============================================================================
-- QUERY 9: Multi-Domain Join - Ultra High-Risk Identification
-- Purpose: Join 5 domain tables to isolate patients matching multiple acute criteria.
-- Recruiter Signal: Multi-table relational join orchestration with granular boolean filters.
-- ==============================================================================
SELECT 
    p.patient_id,
    p.age,
    d.epilepsy_type,
    eeg.mri_ct_result,
    trig.lack_of_sleep,
    trig.stress_or_anxiety,
    rx.missed_medication
FROM patients p
INNER JOIN diagnoses d ON p.patient_id = d.patient_id
INNER JOIN eeg_mri_results eeg ON d.encounter_id = eeg.encounter_id
INNER JOIN lifestyle_triggers trig ON d.encounter_id = trig.encounter_id
INNER JOIN prescriptions rx ON d.encounter_id = rx.encounter_id
WHERE eeg.mri_ct_result = 'Abnormal'
  AND rx.missed_medication = 'Yes'
  AND (trig.lack_of_sleep = 'Yes' OR trig.stress_or_anxiety = 'Yes')
LIMIT 10;


-- ==============================================================================
-- QUERY 10: Composite Clinical Risk Scoring & Cohort Stratification
-- Purpose: Construct a weighted composite risk score (0-100) and group into risk tiers.
-- Recruiter Signal: In-SQL feature engineering and cohort stratification using NTILE().
-- ==============================================================================
WITH ClinicalRiskScoring AS (
    SELECT 
        p.patient_id,
        p.age,
        (CASE WHEN mh.stroke_history = 'Yes' THEN 25 ELSE 0 END +
         CASE WHEN mh.head_injury = 'Yes' THEN 15 ELSE 0 END +
         CASE WHEN mh.brain_tumor = 'Yes' THEN 20 ELSE 0 END +
         CASE WHEN eeg.mri_ct_result = 'Abnormal' THEN 20 ELSE 0 END +
         CASE WHEN e.seizure_frequency >= 1 THEN 20 ELSE 0 END) AS raw_risk_score
    FROM patients p
    INNER JOIN medical_histories mh ON p.patient_id = mh.patient_id
    INNER JOIN encounters e ON p.patient_id = e.patient_id
    INNER JOIN eeg_mri_results eeg ON e.encounter_id = eeg.encounter_id
)
SELECT 
    patient_id,
    age,
    raw_risk_score,
    CASE 
        WHEN raw_risk_score >= 60 THEN 'Tier 1: High Risk'
        WHEN raw_risk_score BETWEEN 30 AND 59 THEN 'Tier 2: Moderate Risk'
        ELSE 'Tier 3: Low Risk'
    END AS clinical_risk_strata,
    NTILE(4) OVER (ORDER BY raw_risk_score DESC) AS risk_quartile
FROM ClinicalRiskScoring
ORDER BY raw_risk_score DESC;


-- ==============================================================================
-- QUERY 11: Care Team / Provider Hierarchy (Recursive CTE Example)
-- Purpose: Demonstrates recursive CTE capability for hierarchical structures.
-- Recruiter Signal: Advanced SQL technique showcasing proficiency with recursive queries.
-- ==============================================================================
WITH RECURSIVE ProviderHierarchy AS (
    -- Anchor member
    SELECT 1 AS provider_id, 'Dr. Sarah Jenkins' AS provider_name, 'Chief of Neurology' AS title, NULL AS manager_id, 1 AS lvl
    UNION ALL
    -- Recursive member
    SELECT 2, 'Dr. Alan Reyes', 'Epileptologist', 1, 2
    UNION ALL
    SELECT 3, 'Dr. Maria Chen', 'Neurology Resident', 2, 3
)
SELECT * FROM ProviderHierarchy;


-- ==============================================================================
-- QUERY 12: Monthly Admission Cross-Tabulation (Matrix Pivot)
-- Purpose: Pivot monthly encounter volumes across epilepsy types.
-- Recruiter Signal: Manual dynamic pivoting technique for executive dashboarding.
-- ==============================================================================
SELECT 
    DATE_FORMAT(e.encounter_date, '%Y-%m') AS encounter_month,
    COUNT(e.encounter_id) AS total_encounters,
    SUM(CASE WHEN d.epilepsy_type = 'Generalized' THEN 1 ELSE 0 END) AS generalized_count,
    SUM(CASE WHEN d.epilepsy_type = 'Focal' THEN 1 ELSE 0 END) AS focal_count,
    SUM(CASE WHEN d.epilepsy_type = 'Absence' THEN 1 ELSE 0 END) AS absence_count,
    SUM(CASE WHEN d.epilepsy_type = 'Complicated' THEN 1 ELSE 0 END) AS complicated_count
FROM encounters e
INNER JOIN diagnoses d ON e.encounter_id = d.encounter_id
GROUP BY DATE_FORMAT(e.encounter_date, '%Y-%m')
ORDER BY encounter_month ASC;