-- fct_funnel.sql
-- Funnel completion flags at the session level.
-- Each column = 1 if the user reached that stage in the session.

SELECT
    user_pseudo_id,
    session_id,
    session_date,
    session_source,
    session_medium,
    device_category,
    1 AS step_1_session,
    CASE WHEN view_item_count > 0 THEN 1 ELSE 0 END AS step_2_viewed_item,
    CASE WHEN add_to_cart_count > 0 THEN 1 ELSE 0 END AS step_3_added_to_cart,
    CASE WHEN begin_checkout_count > 0 THEN 1 ELSE 0 END AS step_4_began_checkout,
    CASE WHEN purchase_count > 0 THEN 1 ELSE 0 END AS step_5_purchased
FROM {{ ref('fct_sessions') }}