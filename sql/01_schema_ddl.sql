CREATE DATABASE IF NOT EXISTS epilepsy_dw;
USE epilepsy_dw;

SET FOREIGN_KEY_CHECKS = 0;

-- 1. STAGING TABLE (Direct import target for epilepsy_joined.csv)
DROP TABLE IF EXISTS epilepsy_joined_staging;
CREATE TABLE epilepsy_joined_staging (
    patient_id INT,
    age INT,
    gender VARCHAR(10),
    height DECIMAL(5,2),
    weight DECIMAL(5,2),
    family_history VARCHAR(10),
    head_injury VARCHAR(10),
    brain_tumor VARCHAR(10),
    stroke_history VARCHAR(10),
    genetic_disorder VARCHAR(10),
    development_delay VARCHAR(10),
    medication_status VARCHAR(30),
    eeg_abnormality VARCHAR(10),
    mri_ct_result VARCHAR(20),
    seizure_frequency INT,
    seizure_duration INT,
    seizure_type VARCHAR(50),
    aura_before_seizure VARCHAR(10),
    loss_of_consciousness VARCHAR(10),
    muscle_stiffness VARCHAR(10),
    jerky_movements VARCHAR(10),
    postictal_confusion VARCHAR(10),
    blank_stare_episodes VARCHAR(10),
    eye_rolling VARCHAR(10),
    alcohol_or_drug_use VARCHAR(10),
    stress_or_anxiety VARCHAR(10),
    lack_of_sleep VARCHAR(10),
    flashing_lights_sensitivity VARCHAR(10),
    loud_sound_sensitivity VARCHAR(10),
    missed_medication VARCHAR(10),
    epilepsy_type VARCHAR(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. NORMALIZED DOMAIN TABLES (3NF Target Schema)

DROP TABLE IF EXISTS patients;
CREATE TABLE patients (
    patient_id INT PRIMARY KEY,
    age INT NOT NULL,
    gender VARCHAR(10) NOT NULL,
    height_cm DECIMAL(5,2),
    weight_kg DECIMAL(5,2)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS encounters;
CREATE TABLE encounters (
    encounter_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT NOT NULL,
    encounter_date DATETIME NOT NULL,
    encounter_type VARCHAR(30) NOT NULL,
    seizure_frequency INT NOT NULL,
    seizure_duration_sec INT NOT NULL,
    seizure_type VARCHAR(50) NOT NULL,
    CONSTRAINT fk_enc_patient FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS diagnoses;
CREATE TABLE diagnoses (
    diagnosis_id INT PRIMARY KEY AUTO_INCREMENT,
    encounter_id INT NOT NULL,
    patient_id INT NOT NULL,
    epilepsy_type VARCHAR(50) NOT NULL,
    CONSTRAINT fk_diag_enc FOREIGN KEY (encounter_id) REFERENCES encounters(encounter_id) ON DELETE CASCADE,
    CONSTRAINT fk_diag_pat FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS medical_histories;
CREATE TABLE medical_histories (
    history_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT NOT NULL,
    family_history ENUM('Yes', 'No') NOT NULL,
    head_injury ENUM('Yes', 'No') NOT NULL,
    brain_tumor ENUM('Yes', 'No') NOT NULL,
    stroke_history ENUM('Yes', 'No') NOT NULL,
    genetic_disorder ENUM('Yes', 'No') NOT NULL,
    development_delay ENUM('Yes', 'No') NOT NULL,
    CONSTRAINT fk_hist_pat FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS eeg_mri_results;
CREATE TABLE eeg_mri_results (
    result_id INT PRIMARY KEY AUTO_INCREMENT,
    encounter_id INT NOT NULL,
    patient_id INT NOT NULL,
    eeg_abnormality ENUM('Yes', 'No') NOT NULL,
    mri_ct_result VARCHAR(20) NOT NULL,
    CONSTRAINT fk_eeg_enc FOREIGN KEY (encounter_id) REFERENCES encounters(encounter_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS lifestyle_triggers;
CREATE TABLE lifestyle_triggers (
    trigger_id INT PRIMARY KEY AUTO_INCREMENT,
    encounter_id INT NOT NULL,
    patient_id INT NOT NULL,
    alcohol_or_drug_use ENUM('Yes', 'No') NOT NULL,
    stress_or_anxiety ENUM('Yes', 'No') NOT NULL,
    lack_of_sleep ENUM('Yes', 'No') NOT NULL,
    flashing_lights_sensitivity ENUM('Yes', 'No') NOT NULL,
    loud_sound_sensitivity ENUM('Yes', 'No') NOT NULL,
    CONSTRAINT fk_trig_enc FOREIGN KEY (encounter_id) REFERENCES encounters(encounter_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS prescriptions;
CREATE TABLE prescriptions (
    prescription_id INT PRIMARY KEY AUTO_INCREMENT,
    encounter_id INT NOT NULL,
    patient_id INT NOT NULL,
    medication_status VARCHAR(30) NOT NULL,
    missed_medication ENUM('Yes', 'No') NOT NULL,
    CONSTRAINT fk_rx_enc FOREIGN KEY (encounter_id) REFERENCES encounters(encounter_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;

