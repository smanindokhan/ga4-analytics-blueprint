-- Q2: D7 and D30 retention by acquisition source.

SELECT
    acquisition_source,
    COUNT(DISTINCT user_pseudo_id) AS cohort_size,
    ROUND(100.0 * SUM(retained_day1)
          / COUNT(DISTINCT user_pseudo_id), 1) AS day1_retention_pct,
    ROUND(100.0 * SUM(retained_day7)
          / COUNT(DISTINCT user_pseudo_id), 1) AS day7_retention_pct,
    ROUND(100.0 * SUM(retained_day30)
          / COUNT(DISTINCT user_pseudo_id), 1) AS day30_retention_pct
FROM {{ ref('fct_retention') }}
GROUP BY acquisition_source
HAVING cohort_size >= 50            -- filter noise from tiny cohorts
ORDER BY day7_retention_pct DESC