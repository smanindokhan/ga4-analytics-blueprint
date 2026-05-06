-- Q3: Which product categories drive the most view-to-purchase sessions?

WITH item_events AS (
    SELECT
        user_pseudo_id,
        session_id,
        event_name,
        (SELECT value.string_value
         FROM UNNEST(event_params)
         WHERE key = 'item_category') AS item_category,
        (SELECT value.string_value
         FROM UNNEST(event_params)
         WHERE key = 'item_name') AS item_name
    FROM {{ ref('stg_events') }}
    WHERE event_name IN ('view_item', 'purchase')
),

category_sessions AS (
    SELECT
        item_category,
        session_id,
        COUNTIF(event_name = 'view_item') AS view_count,
        COUNTIF(event_name = 'purchase') AS purchase_count
    FROM item_events
    WHERE item_category IS NOT NULL
    GROUP BY item_category, session_id
)

SELECT
    item_category,
    COUNT(DISTINCT session_id) AS sessions_with_views,
    SUM(purchase_count) AS total_purchases,
    ROUND(100.0 * COUNTIF(purchase_count > 0)
          / COUNT(DISTINCT session_id), 2) AS view_to_purchase_rate
FROM category_sessions
GROUP BY item_category
ORDER BY view_to_purchase_rate DESC