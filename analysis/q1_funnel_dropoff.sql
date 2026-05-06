-- Q1: Where do users drop off in the purchase funnel?
-- Segmented by acquisition channel.

SELECT
    session_source,
    COUNT(*) AS total_sessions,
    SUM(step_2_viewed_item) AS viewed_item,
    SUM(step_3_added_to_cart) AS added_to_cart,
    SUM(step_4_began_checkout) AS began_checkout,
    SUM(step_5_purchased) AS purchased,

    -- Drop-off rates between each step
    ROUND(100.0 * SUM(step_2_viewed_item) / COUNT(*), 1)
        AS pct_reached_view_item,
    ROUND(100.0 * SUM(step_3_added_to_cart)
          / NULLIF(SUM(step_2_viewed_item), 0), 1)
        AS pct_view_to_cart,
    ROUND(100.0 * SUM(step_4_began_checkout)
          / NULLIF(SUM(step_3_added_to_cart), 0), 1)
        AS pct_cart_to_checkout,
    ROUND(100.0 * SUM(step_5_purchased)
          / NULLIF(SUM(step_4_began_checkout), 0), 1)
        AS pct_checkout_to_purchase,

    -- Overall conversion
    ROUND(100.0 * SUM(step_5_purchased) / COUNT(*), 2)
        AS overall_conversion_rate
FROM {{ ref('fct_funnel') }}
GROUP BY session_source
ORDER BY total_sessions DESC