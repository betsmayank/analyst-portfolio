# KPI Dictionary

Definitions are provisional until the data is loaded and reconciled. If source structure requires a change, the final README will document it.

## Project 1: Olist E-commerce

| KPI | Definition | Grain / filter | Important caveat |
|---|---|---|---|
| Product GMV (BRL) | Sum of `price` across order items belonging to delivered orders | Delivered order items | Excludes freight; not net revenue or profit |
| Delivered orders | Distinct order IDs with status `delivered` | Order | Excludes cancelled/unavailable orders |
| Average order value (BRL) | Product GMV divided by delivered orders | Delivered order | Uses product value only, excluding freight |
| Average delivery days | Average calendar duration from purchase timestamp to customer delivery timestamp | Delivered order with both timestamps | Null/invalid dates excluded |
| Late delivery rate | Delivered orders where actual customer delivery is later than estimated delivery, divided by eligible delivered orders with both dates | Delivered order | Denominator excludes missing comparison dates |
| Average review score | Average recorded review score | Review / order after duplicate handling | Scores are ordinal; interpret carefully |
| Repeat customer rate | Unique customers with more than one delivered order divided by unique customers with at least one delivered order | `customer_unique_id` | Customer identity must use `customer_unique_id` |
| Freight-to-product-value ratio | Freight value divided by product GMV for the same delivered orders | Delivered order items | A logistics-cost proxy, not profit impact |

## Project 2: Synthetic Salesforce CRM

| KPI | Definition | Caveat |
|---|---|---|
| Lead conversion rate | Converted leads divided by all leads in the defined created-date cohort | Must disclose cohort window and status handling |
| Opportunity win rate | Closed-won opportunities divided by closed-won plus closed-lost opportunities | Excludes open opportunities |
| Open pipeline | Sum of amount for open opportunities | Not booked revenue |
| Weighted pipeline | Sum of open opportunity amount multiplied by its probability | Forecast proxy, not guaranteed revenue |
| Average won deal size | Sum of closed-won opportunity amount divided by closed-won opportunity count | Uses synthetic records |
| Sales cycle days | Average days between opportunity creation and close for closed-won opportunities | Uses synthetic dates |

## Project 3: GA4 Funnel

| KPI | Definition | Caveat |
|---|---|---|
| Sessions | Distinct user-and-session identifiers with a valid GA4 session ID | Excludes events without a usable session identifier |
| Product-view sessions | Sessions containing `view_item` | Session-level metric, not event count |
| Add-to-cart sessions | Sessions containing `add_to_cart` | Session-level metric |
| Checkout sessions | Sessions containing `begin_checkout` | Session-level metric |
| Purchase sessions | Sessions containing `purchase` | Session-level metric |
| Stage conversion rate | Sessions reaching a funnel stage divided by sessions reaching the previous stage | Final funnel must enforce timestamp order or explicitly state it is a stage-presence funnel |
| Session purchase rate | Purchase sessions divided by sessions | Not the same as user conversion rate |

## Reporting rules

- Always state currency and date range.
- Always state the denominator for percentages.
- Label sample, synthetic and obfuscated data prominently.
- Do not describe GMV or open pipeline as profit or realised revenue.
- Do not infer causation from descriptive correlations.
