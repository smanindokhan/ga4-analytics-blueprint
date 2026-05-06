# GA4 Analytics Blueprint

A complete end-to-end analytics system built on GA4 BigQuery exports. Demonstrates data modeling, transformation, and insight generation from raw event data to business-ready metrics.

---

## Overview

This project builds a production-grade analytics foundation using:
- **Raw Data:** GA4 BigQuery export (Google Merchandise Store)
- **Transformation:** dbt (data build tool) for staging and mart layers
- **Analysis:** SQL for business question answering
- **Visualization:** Looker Studio dashboard

The system answers 5 core business questions about user behavior, funnel efficiency, retention, and revenue.

---

## Key Findings

### 1. Checkout is the critical conversion bottleneck, not cart abandonment

Only 19% of sessions result in a product view, but 82% of users who begin checkout complete the purchase. The real friction is pre-checkout — getting users to even look at products. 

**Implication:** UX optimization efforts should focus on product discovery and item pages, not checkout flow refinement. The data suggests payment hesitation is not the primary barrier.

### 2. Referral traffic (shop.googlemerchandisestore.com) drives 15x higher Day-1 retention than paid search

Referred users show 15.4% Day-1 retention vs 4.2% for Google organic and 1.4% for direct traffic. This cohort also converts at 2.3x the rate of organic (1.45% vs 0.77%).

**Implication:** Referral/affiliate partnerships are disproportionately valuable for both conversion and retention. Budget allocation should reflect that referral traffic drives higher-quality users, not just volume.

### 3. Purchasing sessions involve 9x more page views and 14x more engagement than non-purchasing sessions

Converted users average 28.6 pageviews and 717 seconds of engagement per session, vs 3.3 pageviews and 51 seconds for non-converters. This behavioral gap is too large to be explained by intent alone.

**Implication:** Session depth is a leading indicator of purchase intent. Onboarding and content strategy should emphasize engagement — keeping users exploring longer correlates strongly with conversion.

---

## Architecture

```
Raw GA4 Events (BigQuery public dataset)
    ↓
stg_events (unnested, flattened event layer)
    ↓
    ├─→ fct_sessions (session-grain facts)
    │       ├─→ fct_funnel (conversion stages)
    │       ├─→ fct_retention (cohort D1/D7/D30)
    │       └─→ dim_users (user-level metrics)
    │
    └─→ Looker Studio (visualization)
```

All models are defined in dbt with dependencies, tests, and documentation.

---

## Data Model

### Staging Layer (`stg_events`)
- One row per GA4 event
- Unnests all nested `event_params` into flat columns
- Standardizes timestamps and data types

### Mart Layer (fact tables)
- **`fct_sessions`:** One row per session, with aggregated event counts and revenue
- **`fct_funnel`:** Session-level flags for each funnel stage (viewed → carted → checkedout → purchased)
- **`fct_retention`:** User-level cohort flags (Day 1, 7, 30 retention)
- **`dim_users`:** User dimension with lifetime metrics and purchase segments

### Analysis Queries (5 core questions)
1. **Funnel drop-off by channel** — identifies which acquisition sources have quality issues
2. **Retention by source** — cohort-based retention analysis by acquisition channel
3. **Product performance** — category-level view-to-purchase rates (skipped due to data constraints)
4. **Session behavior predictors** — what behaviors distinguish converters from browsers
5. **Revenue by user type and device** — lifetime value segmentation

---

## Stack

- **Data Warehouse:** BigQuery
- **Transformation:** dbt (data build tool)
- **Modeling Language:** SQL + Jinja2
- **Visualization:** Looker Studio
- **Version Control:** Git/GitHub

---

## Key Metrics

| Metric | Value | Insight |
|--------|-------|---------|
| Overall conversion rate | 0.77% - 2.32% | Varies 3x by channel; referral is strongest |
| Day-1 retention | 1.4% - 15.4% | Referral users retain at 11x the rate of direct |
| Avg session duration (converters) | 1340 seconds | 22 minutes — deep engagement signals purchase intent |
| Avg session duration (non-converters) | 158 seconds | 2.6 minutes — brief browse sessions rarely convert |
| Mobile % of sessions | 39.8% | Mobile is 40% of volume but lower conversion |

---

## Running This Project

### Prerequisites
- Python 3.8+
- BigQuery project with public dataset access
- dbt installed (`pip install dbt-bigquery`)

### Setup

1. **Authenticate with BigQuery**
```bash
gcloud auth application-default login
```

2. **Configure dbt profile**
Create `~/.dbt/profiles.yml`:
```yaml
ga4_analytics_blueprint:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: oauth
      project: your-gcp-project-id
      dataset: dbt_dev
      threads: 4
      location: US
```

3. **Run dbt models**
```bash
dbt debug                    # Test connection
dbt run                      # Build all models
dbt test                     # Run data tests
dbt docs generate && dbt docs serve  # View lineage
```

4. **Query in BigQuery**
Run the analysis queries in `/analysis/` folder to generate insights.

5. **Connect to Looker Studio**
Create a new report and connect to your BigQuery dataset's `dbt_dev` schema.

---

## Project Structure

```
ga4-analytics-blueprint/
├── README.md                          # This file
├── measurement-plan.md                # Analytics spec and definitions
├── dbt_project.yml                    # dbt configuration
│
├── schema/
│   ├── events_schema.sql              # Raw GA4 table DDL reference
│   └── event_params_reference.md      # Parameter extraction guide
│
├── models/
│   ├── sources.yml                    # Source definitions
│   ├── schema.yml                     # Model documentation and tests
│   ├── staging/
│   │   └── stg_events.sql
│   └── marts/
│       ├── fct_sessions.sql
│       ├── fct_funnel.sql
│       ├── fct_retention.sql
│       └── dim_users.sql
│
├── analysis/
│   ├── q1_funnel_dropoff.sql
│   ├── q2_retention_by_source.sql
│   ├── q4_purchase_predictors.sql
│   └── q5_revenue_by_user_type.sql
│
└── assets/
    ├── dbt-lineage.png
```

---

## Dashboard

A Looker Studio dashboard visualizes:
- **Funnel flow** by acquisition channel 
- **Retention cohorts** by source 
- **Revenue distribution** by user type and device 
- **KPI cards** for total sessions, conversion rate, and average LTV

[[Looker Dashboard](https://datastudio.google.com/reporting/0b48080b-a73a-46c7-884c-4daadc1a67af)]

---

## Measurement Philosophy

This analytics system is built on a few core principles:

1. **One source of truth** — All insights come from the same dbt models, eliminating metric conflicts
2. **Testable assumptions** — Data quality tests run on every model; failures surface immediately
3. **Documented decisions** — Every metric has a definition in `schema.yml`; no ambiguity about what numbers mean
4. **Layered abstraction** — Raw data is never queried directly; all analysis uses marts
5. **Reproducibility** — All SQL is versioned in Git; any analysis can be re-run at any time

---

## Known Limitations

- **Session-level attribution:** Revenue is attributed to the session where purchase occurred, not the first-touch session
- **Obfuscated data:** The sample dataset has non-persistent user IDs, limiting true user-level cohort analysis
- **Date range:** Analysis covers 2021 calendar year only
- **No custom events:** Domain-specific instrumentation (events specific to your product) is not included

---

## Questions?

This measurement plan (`measurement-plan.md`) documents all business questions, event definitions, and analytical methodology. It's the reference guide for understanding what each metric means and how it's calculated.

See `schema/event_params_reference.md` for a quick lookup of GA4 parameter names and extraction patterns.

---

**Built with dbt, BigQuery, and SQL**  