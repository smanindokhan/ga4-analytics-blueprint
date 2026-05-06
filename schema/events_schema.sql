-- events_schema.sql
-- Documents the structure of the raw GA4 BigQuery export.
-- This table is owned by Google (public dataset).
-- In production, this DDL would represent a table your team owns.
-- Reference: bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*

/*
  TABLE: events_YYYYMMDD
  GRAIN: One row per event fired per user session
  PARTITION: event_date (DATE)
  NOTE: GA4 exports one table per day. Queried using wildcard _TABLE_SUFFIX.
*/

CREATE TABLE IF NOT EXISTS `your_project.ga4_raw.events` (
    event_date              DATE,           -- Date event was logged (YYYYMMDD)
    event_timestamp         INT64,          -- Microseconds since epoch (UTC)
    event_name              STRING,         -- e.g. page_view, purchase, session_start
    event_params            ARRAY<STRUCT<   -- Key-value pairs per event (UNNEST to query)
        key STRING,
        value STRUCT
            string_value    STRING,
            int_value       INT64,
            float_value     FLOAT64,
            double_value    FLOAT64
        >
    >>,
    user_pseudo_id          STRING,         -- Anonymous user identifier (cookie-based)
    user_properties         ARRAY<STRUCT<   -- User-scoped properties (UNNEST to query)
        key STRING,
        value STRUCT
            string_value    STRING,
            int_value       INT64,
            float_value     FLOAT64,
            double_value    FLOAT64,
            set_timestamp_micros INT64
        >
    >>,
    device STRUCT
        category            STRING,         -- mobile / tablet / desktop
        mobile_brand_name   STRING,
        mobile_model_name   STRING,
        operating_system    STRING,
        language            STRING,
        web_info STRUCT
            browser         STRING,
            browser_version STRING
        >
    >,
    geo STRUCT
        continent           STRING,
        country             STRING,
        region              STRING,
        city                STRING
    >,
    traffic_source STRUCT
        name                STRING,         -- Campaign name
        medium              STRING,         -- e.g. organic, cpc, email
        source              STRING          -- e.g. google, facebook, (direct)
    >,
    ecommerce STRUCT
        transaction_id      STRING,
        purchase_revenue    FLOAT64,        -- Revenue in local currency
        refund_value        FLOAT64,
        shipping_value      FLOAT64,
        tax_value           FLOAT64
    >,
    items                   ARRAY<STRUCT<   -- Line items per transaction
        item_id             STRING,
        item_name           STRING,
        item_category       STRING,
        price               FLOAT64,
        quantity            INT64
    >>
);