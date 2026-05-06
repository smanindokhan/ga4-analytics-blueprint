-- stg_events.sql
-- Flattens the raw GA4 event export into one row per event.
-- All downstream models reference this, never the raw source directly.

WITH raw AS (
    SELECT
        event_date,
        event_timestamp,
        event_name,
        event_params,
        user_pseudo_id,
        user_properties,
        device.category                          AS device_category,
        device.operating_system                  AS operating_system,
        geo.country                              AS country,
        geo.city                                 AS city,
        traffic_source.source                    AS session_source,
        traffic_source.medium                    AS session_medium,
        traffic_source.name                      AS campaign_name,
        ecommerce.purchase_revenue               AS purchase_revenue,
        ecommerce.transaction_id                 AS transaction_id
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
    WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20211231'
),

flattened AS (
    SELECT
        -- identifiers
        user_pseudo_id,
        event_name,
        event_date,
        TIMESTAMP_MICROS(event_timestamp) AS event_timestamp,

        -- session key (GA4 uses ga_session_id param)
        (SELECT value.int_value
         FROM UNNEST(event_params)
         WHERE key = 'ga_session_id') AS session_id,

        -- page info
        (SELECT value.string_value
         FROM UNNEST(event_params)
         WHERE key = 'page_location') AS page_location,

        -- engagement
        (SELECT value.int_value
         FROM UNNEST(event_params)
         WHERE key = 'engagement_time_msec') AS engagement_time_msec,

        -- ecommerce
        purchase_revenue,
        transaction_id,

        -- session dimensions
        session_source,
        session_medium,
        campaign_name,
        device_category,
        operating_system,
        country,
        city
    FROM raw
)

SELECT * FROM flattened