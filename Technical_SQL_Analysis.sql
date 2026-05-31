-- =================================================================================
-- PROJECT: Finance Revenue Reconciliation Tool
-- TITLE: Technical SQL Analysis & Data Quality Audit Suite
-- DESCRIPTION: Advanced SQL queries for automated reconciliation, risk ranking, 
--              and proactive data quality auditing.
-- =================================================================================

-- 1. ADVANCED RECONCILIATION: Using CTEs to Modularize Logic
-- This query uses a CTE to isolate variance calculations, making the code 
-- cleaner, more readable, and easier to maintain for enterprise reporting.

WITH VarianceCalcs AS (
    SELECT 
        l.loan_id,
        l.lender_name,
        r.expected_interest_income,
        r.actual_interest_received,
        (r.expected_interest_income - r.actual_interest_received) AS interest_diff
    FROM loan_tape l
    JOIN revenue_recon r ON l.loan_id = r.loan_id
)
SELECT 
    lender_name,
    COUNT(loan_id) AS total_exception_count,
    SUM(interest_diff) AS total_interest_leakage,
    AVG(interest_diff) AS avg_variance_per_loan
FROM VarianceCalcs
WHERE interest_diff > 0
GROUP BY lender_name
ORDER BY total_interest_leakage DESC;


-- 2. RISK RANKING: Window Functions for Comparative Analysis
-- Uses RANK() to identify which lenders are driving the most significant revenue variances,
-- essential for partner risk assessment and audit prioritization.

SELECT 
    l.lender_name,
    SUM(ABS(r.expected_interest_income - r.actual_interest_received)) AS total_absolute_variance,
    RANK() OVER (ORDER BY SUM(ABS(r.expected_interest_income - r.actual_interest_received)) DESC) as variance_rank
FROM loan_tape l
JOIN revenue_recon r ON l.loan_id = r.loan_id
GROUP BY l.lender_name;


-- 3. PROACTIVE DATA QUALITY AUDIT
-- A proactive audit script to identify "garbage data" (e.g., negative amounts, future dates)
-- before it enters the reconciliation process, ensuring the "garbage-in, garbage-out" 
-- principle is mitigated.

SELECT 
    loan_id,
    CASE 
        WHEN principal_amount <= 0 THEN 'Invalid Principal'
        WHEN disbursement_date > CURRENT_DATE THEN 'Future Date Error'
        WHEN actual_interest_received < 0 THEN 'Negative Interest Recorded'
        ELSE 'Pass'
    END AS data_quality_flag
FROM loan_tape
WHERE principal_amount <= 0 
   OR disbursement_date > CURRENT_DATE
   OR actual_interest_received < 0;
