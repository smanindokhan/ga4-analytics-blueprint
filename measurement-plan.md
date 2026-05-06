# Analytics Measurement Plan
## Travel E-Commerce — GA4 Implementation Blueprint
---

## 1. Purpose

This document defines the analytics measurement strategy for a 
travel e-commerce product. It specifies the business questions 
driving instrumentation decisions, the event taxonomy, BigQuery 
export schema, and the KPIs surfaced in the reporting layer.

This is a portfolio implementation using the GA4 Obfuscated 
Sample dataset (Google Merchandise Store) as a structural proxy 
for a travel eSIM product's data model.

---

## 2. Business Questions This Instrumentation Answers

| # | Question | Decision It Enables | Primary Stakeholder |
|---|----------|--------------------|--------------------|
| Q1 | Where do users drop off in the purchase funnel, and does it vary by acquisition channel? | Channel budget reallocation | Growth / Marketing |
| Q2 | What is D7 and D30 retention by first session source? | Retention intervention timing | Product |
| Q3 | Which product categories have the highest view-to-purchase rate? | Merchandising & pricing strategy | Revenue |
| Q4 | What session behaviors predict purchase? | Onboarding and UX optimization | Product |
| Q5 | How does revenue per user differ across new vs returning users by device? | Loyalty program and device-specific UX | Revenue |

---

## 3. Event Taxonomy

### Core Events (auto-collected by GA4)
| Event | Trigger | Key Parameters |
|-------|---------|----------------|
| `session_start` | New session begins | session_id, source, medium |
| `page_view` | Any page loaded | page_location, page_title |
| `first_visit` | First time user visits | — |
| `user_engagement` | User engaged ≥10s | engagement_time_msec |

### Recommended Events (travel e-commerce context)
| Event | Trigger | Key Parameters |
|-------|---------|----------------|
| `view_item` | Product detail viewed | item_id, item_name, item_category, price |
| `add_to_cart` | Item added to cart | item_id, value, currency |
| `begin_checkout` | Checkout initiated | value, currency, coupon |
| `purchase` | Transaction completed | transaction_id, value, items[] |
| `login` | User authenticates | method |
| `sign_up` | New account created | method |

### Custom Events (instrumentation design decisions)
| Event | Trigger | Rationale |
|-------|---------|-----------|
| `plan_comparison` | User views 2+ plans side-by-side | Signals high purchase intent; not captured by standard events |
| `coverage_check` | User checks coverage for a country | Key intent signal for eSIM; maps to destination demand |
| `checkout_abandon` | User exits mid-checkout | Distinct from cart abandonment; enables recovery flows |

---

## 4. User Properties Schema
| Property | Type | Description |
|----------|------|-------------|
| `user_type` | string | new / returning |
| `account_created_date` | string (YYYY-MM-DD) | First purchase or signup date |
| `lifetime_orders` | integer | Total completed purchases |
| `preferred_device` | string | Device category of majority sessions |

---

## 5. Funnel Definition
- session_start
- view_item
- add_to_cart
- begin_checkout
- purchase

Drop-off rate is calculated between each consecutive step. 
Segmented by: first_session_source, device_category, user_type.

---

## 6. Known Limitations & Assumptions
- Dataset is obfuscated; user_ids are not persistent across 
  sessions in some cases
- Revenue figures are approximate (sample data)
- Custom events (Q3 above) are modeled analytically from 
  existing event parameters, not from actual custom 
  instrumentation