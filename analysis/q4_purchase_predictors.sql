-- Q4: What session behaviors distinguish purchasing vs non-purchasing sessions?

SELECT
    is_converted_session,
    COUNT(*) AS session_count,
    ROUND(AVG(pageview_count), 1) AS avg_pageviews,
    ROUND(AVG(event_count), 1) AS avg_events,
    ROUND(AVG(total_engagement_seconds), 0) AS avg_engagement_seconds,
    ROUND(AVG(view_item_count), 1) AS avg_items_viewed,
    ROUND(AVG(session_duration_seconds), 0) AS avg_session_duration_seconds,
    COUNTIF(device_category = 'mobile') AS mobile_sessions,
    COUNTIF(device_category = 'desktop') AS desktop_sessions,
    ROUND(100.0 * COUNTIF(device_category = 'mobile')
          / COUNT(*), 1) AS pct_mobile
FROM {{ ref('fct_sessions') }}
GROUP BY is_converted_session