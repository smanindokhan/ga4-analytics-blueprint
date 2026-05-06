-- Q5: Revenue per user, new vs returning, by device type.

SELECT
    user_type,
    primary_device,
    COUNT(DISTINCT user_pseudo_id) AS user_count,
    SUM(lifetime_revenue) AS total_revenue,
    ROUND(SUM(lifetime_revenue)
          / NULLIF(COUNT(DISTINCT user_pseudo_id), 0), 2) AS avg_revenue_per_user,
    ROUND(AVG(total_purchases), 2) AS avg_purchases_per_user,
    ROUND(100.0 * COUNTIF(total_purchases > 0)
          / COUNT(*), 1) AS pct_ever_purchased,
    purchase_segment,
    COUNT(DISTINCT CASE WHEN purchase_segment = 'repeat_buyer'
          THEN user_pseudo_id END) AS repeat_buyers
FROM {{ ref('dim_users') }}
GROUP BY user_type, primary_device, purchase_segment
ORDER BY avg_revenue_per_user DESC