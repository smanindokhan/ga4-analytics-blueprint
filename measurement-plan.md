# Analytics Measurement Plan
## GA4 Ecommerce — Implementation Blueprint

---

## 1. Purpose

This document defines the analytics measurement strategy for an ecommerce product 
using GA4 BigQuery exports. It specifies the business questions driving the data 
model, the events available, user properties, funnel definitions, and KPIs 
surfaced in reporting.

This portfolio project uses the GA4 Obfuscated Sample dataset 
(Google Merchandise Store public dataset in BigQuery) as the data source.

---

## 2. Business Questions This Measurement System Answers

| # | Question | Decision It Enables | Primary Stakeholder |
|---|----------|--------------------|--------------------|
| Q1 | Where do users drop off in the purchase funnel, and does it vary by acquisition channel? | Channel budget reallocation and UX optimization prioritization | Growth / Marketing |
| Q2 | What is D7 and D30 retention by first session source? | Retention cohort quality assessment and channel lifetime value | Product |
| Q3 | Which product categories have the highest view-to-purchase rate? | Merchandising and category-level strategy | Revenue |
| Q4 | What session behaviors distinguish purchasing from non-purchasing sessions? | Onboarding and UX optimization targets | Product |
| Q5 | How does revenue per user differ across new vs returning users by device? | Loyalty program design and device investment prioritization | Revenue |

---

## 3. Event Taxonomy

### Core Events (GA4 auto-collected)

GA4 automatically captures these events without custom instrumentation.

| Event | Trigger | Key Parameters |
|-------|---------|----------------|
| `session_start` | New session begins | session_id, source, medium, campaign |
| `page_view` | Page loads in app or web | page_location, page_title, page_referrer |
| `first_visit` | First time user visits | — |
| `user_engagement` | User active ≥10s | engagement_time_msec |

### Ecommerce Events (standard GA4)

Standard ecommerce events that require instrumentation via gtag or Firebase SDK.

| Event | Trigger | Key Parameters | Present in Dataset |
|-------|---------|----------------|-------------------|
| `view_item` | Product detail page viewed | item_id, item_name, item_category, price | ✓ Yes |
| `add_to_cart` | Item added to cart | item_id, value, currency | ✓ Yes |
| `begin_checkout` | Checkout process initiated | value, currency, coupon | ✓ Yes |
| `purchase` | Transaction completed | transaction_id, value, items[], currency | ✓ Yes |

All ecommerce events present in this dataset and used in the analysis.

---

## 4. User Properties Schema

User properties are scoped to individual users and persist across sessions.

| Property | Type | Source | Description | Used In |
|----------|------|--------|-------------|---------|
| `user_pseudo_id` | string | GA4 native | Anonymous user identifier (cookie-based) | all models |
| `first_seen_date` | date | stg_events | Date of user's first session | dim_users |
| `last_seen_date` | date | stg_events | Date of user's most recent session | dim_users |
| `acquisition_source` | string | first session | Traffic source of user's first session (google, facebook, direct, etc.) | fct_retention, Q2 |
| `primary_device` | string | session history | Most common device category across sessions (mobile/desktop/tablet) | dim_users, Q5 |
| `total_sessions` | integer | session count | Number of sessions attributed to this user | dim_users |
| `lifetime_revenue` | float | purchase events | Sum of all session revenue | dim_users, Q5 |
| `total_purchases` | integer | session count | Count of sessions with purchase event | dim_users |
| `purchase_segment` | string | derived | never_purchased / one_time_buyer / repeat_buyer | Q5 |
| `user_type` | string | derived | new (1 session) / returning (2+ sessions) | Q2, Q5 |

### Extraction Logic

- **`acquisition_source`:** First non-null `session_source` in user's session history
- **`primary_device`:** Mode (most frequent) of `device_category` across sessions
- **`user_type`:** Derived from total_sessions count (1 = new, 2+ = returning)
- **`purchase_segment`:** Business logic on total_purchases (0 / 1 / 2+)

---

## 5. Funnel Definition

### Purchase Funnel Stages

```
Stage 1: Session Start
    ↓ (100% of all sessions)
    
Stage 2: Item Viewed
    ↓ (% of sessions with view_item event)
    
Stage 3: Item Added to Cart
    ↓ (% of Stage 2 sessions with add_to_cart)
    
Stage 4: Checkout Initiated
    ↓ (% of Stage 3 sessions with begin_checkout)
    
Stage 5: Purchase Completed
    ↓ (% of Stage 4 sessions with purchase event)
```

### Funnel Grain & Metrics

- **Grain:** Session level (one row = one session)
- **Denominator:** All sessions = Stage 1 (reference = 100%)
- **Conversion:** Session reached Stage 5 (purchase event fired)
- **Drop-off rate:** `(Stage N sessions - Stage N+1 sessions) / Stage N sessions × 100%`
- **Completion rate:** `Stage 5 sessions / Stage 1 sessions × 100%`

### Segmentation Dimensions

Funnel is analyzed by:

| Dimension | Values | Purpose |
|-----------|--------|---------|
| `session_source` | organic, direct, google, facebook, email, etc. | Identify which channels drive high/low quality traffic |
| `device_category` | mobile, desktop, tablet | Identify device-specific UX friction |
| `user_type` | new, returning | New users may need more encouragement; returning may convert faster |

---

## 6. Known Limitations

### Data Quality

- **Obfuscated user IDs:** `user_pseudo_id` is not persistent across some sessions 
  due to dataset obfuscation. Cohort analysis is less reliable than production data.
- **Sample dataset:** This is a sample of Google Merchandise Store traffic, not 
  the complete population.
- **Revenue obfuscation:** Revenue figures are approximate, not actual transaction values.

### Attribution & Analysis Scope

- **Session-level attribution:** Revenue attributed to the session where purchase 
  occurred, not to the first-touch session. Multi-touch attribution not modeled.
- **No cross-device tracking:** Users switching devices appear as separate entities.
- **No timing data:** We capture event presence (did checkout happen?), not 
  duration (how long did checkout take?).

### Analysis Period

- **Date range:** 2021 calendar year (2021-01-01 to 2021-12-31)
- **No real-time data:** Analysis is historical; no live/streaming component

---

## 7. Data Model Architecture

```
bigquery-public-data.ga4_obfuscated_sample_ecommerce
    ↓
stg_events 
  (raw GA4 events, unnested params)
    ↓
    ├─→ fct_sessions 
    │   (one row per session, aggregated metrics)
    │       ↓
    │       ├─→ fct_funnel (funnel stage flags)
    │       │       └→ Q1 Analysis
    │       │
    │       ├─→ fct_retention (D1/D7/D30 flags)
    │       │       └→ Q2 Analysis
    │       │
    │       └─→ dim_users (one row per user)
    │               └→ Q5 Analysis
    │
    └─→ Q3 & Q4 Analysis
        (direct from stg_events and fct_sessions)

Looker Studio Dashboard
    ← Connects to all marts
```

---

## 8. Event Parameter Reference

GA4 event parameters are stored in an ARRAY field and extracted via UNNEST:

```sql
-- String parameter
(SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location')

-- Integer parameter  
(SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')

-- Float parameter
(SELECT value.float_value FROM UNNEST(event_params) WHERE key = 'value')
```

Common keys in this dataset:
- `page_location` (string)
- `ga_session_id` (integer)
- `engagement_time_msec` (integer)
- `item_id` (string)
- `item_name` (string)
- `item_category` (string)
- `value` (float)

---
