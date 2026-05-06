-- dim_users.sql
-- One row per user. Classifies users and computes lifetime metrics.

WITH user_sessions AS (
    SELECT
        user_pseudo_id,
        COUNT(DISTINCT session_id) AS total_sessions,
        MIN(session_date) AS first_seen_date,
        MAX(session_date) AS last_seen_date,
        SUM(session_revenue) AS lifetime_revenue,
        SUM(purchase_count) AS total_purchases,
        MAX(session_source) AS acquisition_source,
        MAX(device_category) AS primary_device
    FROM {{ ref('fct_sessions') }}
    GROUP BY user_pseudo_id
)

SELECT
    *,
    CASE
        WHEN total_purchases = 0 THEN 'never_purchased'
        WHEN total_purchases = 1 THEN 'one_time_buyer'
        ELSE 'repeat_buyer'
    END AS purchase_segment,
    CASE
        WHEN total_sessions = 1 THEN 'new'
        ELSE 'returning'
    END AS user_type
FROM user_sessions