USE epilepsy_dw;

-- 1. Populate Master Patients Table
INSERT INTO patients (patient_id, age, gender, height_cm, weight_kg)
SELECT DISTINCT patient_id, age, gender, height, weight
FROM epilepsy_joined_staging;

-- 2. Populate Encounters Table
INSERT INTO encounters (patient_id, encounter_date, encounter_type, seizure_frequency, seizure_duration_sec, seizure_type)
SELECT 
    patient_id,
    DATE_SUB(NOW(), INTERVAL (patient_id % 365) DAY) AS encounter_date,
    CASE 
        WHEN patient_id % 3 = 0 THEN 'Inpatient' 
        WHEN patient_id % 3 = 1 THEN 'Emergency' 
        ELSE 'Outpatient' 
    END AS encounter_type,
    seizure_frequency,
    seizure_duration,
    seizure_type
FROM epilepsy_joined_staging;

-- 3. Populate Diagnoses Table
INSERT INTO diagnoses (encounter_id, patient_id, epilepsy_type)
SELECT e.encounter_id, e.patient_id, s.epilepsy_type
FROM encounters e
JOIN epilepsy_joined_staging s ON e.patient_id = s.patient_id;

-- 4. Populate Medical Histories Table
INSERT INTO medical_histories (patient_id, family_history, head_injury, brain_tumor, stroke_history, genetic_disorder, development_delay)
SELECT DISTINCT patient_id, family_history, head_injury, brain_tumor, stroke_history, genetic_disorder, development_delay
FROM epilepsy_joined_staging;

-- 5. Populate Diagnostic Results (EEG/MRI)
INSERT INTO eeg_mri_results (encounter_id, patient_id, eeg_abnormality, mri_ct_result)
SELECT e.encounter_id, e.patient_id, s.eeg_abnormality, s.mri_ct_result
FROM encounters e
JOIN epilepsy_joined_staging s ON e.patient_id = s.patient_id;

-- 6. Populate Lifestyle Triggers
INSERT INTO lifestyle_triggers (encounter_id, patient_id, alcohol_or_drug_use, stress_or_anxiety, lack_of_sleep, flashing_lights_sensitivity, loud_sound_sensitivity)
SELECT e.encounter_id, e.patient_id, s.alcohol_or_drug_use, s.stress_or_anxiety, s.lack_of_sleep, s.flashing_lights_sensitivity, s.loud_sound_sensitivity
FROM encounters e
JOIN epilepsy_joined_staging s ON e.patient_id = s.patient_id;

-- 7. Populate Prescriptions
INSERT INTO prescriptions (encounter_id, patient_id, medication_status, missed_medication)
SELECT e.encounter_id, e.patient_id, s.medication_status, s.missed_medication
FROM encounters e
JOIN epilepsy_joined_staging s ON e.patient_id = s.patient_id;