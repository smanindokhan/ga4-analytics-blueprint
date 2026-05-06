-- fct_retention.sql
-- Cohort-based retention model. Cohort = first session date.
-- Calculates whether each user returned on Day 1, 7, and 30.

WITH first_sessions AS (
    SELECT
        user_pseudo_id,
        MIN(session_date) AS cohort_date,
        MAX(session_source) AS acquisition_source
    FROM {{ ref('fct_sessions') }}
    GROUP BY user_pseudo_id
),

all_sessions AS (
    SELECT
        user_pseudo_id,
        session_date
    FROM {{ ref('fct_sessions') }}
),

cohort_joined AS (
    SELECT
        f.user_pseudo_id,
        f.cohort_date,
        f.acquisition_source,
        a.session_date,
        DATE_DIFF(a.session_date, f.cohort_date, DAY) AS days_since_first_visit
    FROM first_sessions f
    JOIN all_sessions a USING (user_pseudo_id)
)

SELECT
    user_pseudo_id,
    cohort_date,
    acquisition_source,
    MAX(CASE WHEN days_since_first_visit = 1 THEN 1 ELSE 0 END) AS retained_day1,
    MAX(CASE WHEN days_since_first_visit BETWEEN 6 AND 8
             THEN 1 ELSE 0 END) AS retained_day7,
    MAX(CASE WHEN days_since_first_visit BETWEEN 28 AND 32
             THEN 1 ELSE 0 END) AS retained_day30
FROM cohort_joined
GROUP BY user_pseudo_id, cohort_date, acquisition_source