# Enterprise Clinical Epilepsy & Neurological Seizure Analytics (MySQL 8.0)

## 📌 Executive Summary
This enterprise SQL portfolio project models, cleans, and analyzes clinical data for **4,856 patients** with epilepsy and seizure-related neurological conditions. The project transforms flat clinical logs into a normalized **3NF relational database schema**, executing advanced analytical queries to track 30-day readmission rates, quantify medication adherence, isolate high-risk clinical cohorts, and measure patient outcomes.

---

## 🗄️ Relational Database Architecture & Schema Design
The warehouse normalizes 31 raw variables into a 7-table 3NF schema in MySQL:
- **`patients`**: Primary demographics registry (age, gender, height, weight).
- **`encounters`**: Inpatient, emergency, and outpatient clinical visits.
- **`diagnoses`**: Epilepsy type classifications (Generalized, Focal, Absence, Complicated).
- **`medical_histories`**: Comorbidities (stroke, head injury, brain tumor, genetic factors).
- **`eeg_mri_results`**: EEG voltage signal spikes and MRI/CT diagnostic findings.
- **`lifestyle_triggers`**: Behavioral triggers (sleep deprivation, stress, flashing lights).
- **`prescriptions`**: Anti-epileptic medication tracking and adherence flags.

---

## 🚀 Key Technical Highlights
- **30-Day Readmissions:** Evaluated inpatient readmission intervals using `LEAD()` window functions.
- **Time-Series Progression:** Quantified elapsed time between seizure events using `LAG()` windowing.
- **Clinical Risk Scoring:** Built composite clinical risk scores (0-100) using multi-factorial `CASE` logic and stratified cohorts into risk quartiles via `NTILE(4)`.
- **Query Performance Optimization:** Applied multi-column B-tree indexes across join keys, reducing execution costs evaluated via `EXPLAIN ANALYZE`.

---

## 📁 Repository Structure
```text
epilepsy-clinical-analytics-sql/
├── .gitignore
├── README.md
├── LICENSE
├── sql/
│   ├── 01_schema_ddl.sql          # Database, staging, & 3NF schema definitions
│   ├── 02_data_import_etl.sql     # Pure SQL ETL pipeline & data population
│   ├── 03_core_analytics.sql      # Advanced analytics (CTEs, Window Functions, Risk Scoring)
│   ├── 04_qa_validation_tests.sql # Automated data quality assertions & anomaly detection
│   └── 05_indexes_performance.sql # B-Tree index creation & EXPLAIN ANALYZE tuning
└── data/
    └── epilepsy_joined.csv        # Source clinical dataset (4,856 records)
