-- fct_sessions.sql
-- One row per session. Aggregates event-level data to session grain.
-- Used as the base for funnel and retention models.

WITH session_events AS (
    SELECT
        user_pseudo_id,
        session_id,
        MIN(event_timestamp) AS session_start_ts,
        MAX(event_timestamp) AS session_end_ts,
        MIN(event_date) AS session_date,
        MAX(session_source) AS session_source,
        MAX(session_medium) AS session_medium,
        MAX(device_category) AS device_category,
        MAX(country) AS country,
        SUM(engagement_time_msec) / 1000.0 AS total_engagement_seconds,
        COUNT(*) AS event_count,
        COUNTIF(event_name = 'page_view') AS pageview_count,
        COUNTIF(event_name = 'view_item')  AS view_item_count,
        COUNTIF(event_name = 'add_to_cart') AS add_to_cart_count,
        COUNTIF(event_name = 'begin_checkout') AS begin_checkout_count,
        COUNTIF(event_name = 'purchase') AS purchase_count,
        MAX(purchase_revenue) AS session_revenue,
        MAX(transaction_id) AS transaction_id
    FROM {{ ref('stg_events') }}
    WHERE session_id IS NOT NULL
    GROUP BY user_pseudo_id, session_id
)

SELECT
    *,
    CASE WHEN purchase_count > 0 THEN TRUE ELSE FALSE END AS is_converted_session,
    TIMESTAMP_DIFF(session_end_ts, session_start_ts, SECOND) AS session_duration_seconds
FROM session_events