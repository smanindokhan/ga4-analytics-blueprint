# GA4 Event Params & User Properties Reference

The GA4 BigQuery export stores event-level and user-level data 
inside REPEATED STRUCT columns — not flat columns. This means 
you can't query them directly; you have to unnest them first.

This document is the reference for every key extracted in 
the staging model.

---

## Extraction Pattern

```sql
-- String value
(SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location')

-- Integer value
(SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')

-- Float value
(SELECT value.float_value FROM UNNEST(event_params) WHERE key = 'value')
```

---

## event_params Key Reference

| Key | Value Type | Present On | Description |
|-----|-----------|------------|-------------|
| `ga_session_id` | int_value | all events | Session identifier |
| `ga_session_number` | int_value | session_start | Nth session for this user |
| `page_location` | string_value | page_view | Full URL |
| `page_title` | string_value | page_view | Document title |
| `page_referrer` | string_value | page_view | Referring URL |
| `engagement_time_msec` | int_value | user_engagement | Time engaged in ms |
| `session_engaged` | string_value | session_start | '1' if engaged session |
| `transaction_id` | string_value | purchase | Order ID |
| `value` | float_value | purchase, add_to_cart | Revenue value |
| `currency` | string_value | purchase | ISO currency code |
| `item_id` | string_value | view_item, purchase | Product SKU |
| `item_name` | string_value | view_item, purchase | Product display name |
| `item_category` | string_value | view_item, purchase | Product category |
| `coupon` | string_value | begin_checkout | Coupon code applied |

---

## user_properties Key Reference

| Key | Value Type | Description |
|-----|-----------|-------------|
| `first_open_time` | int_value | First app open (microseconds) |
| `last_deep_link_referrer` | string_value | Last deep link referrer |
| `medium` | string_value | Acquisition medium at user level |

---
