# KPI Dictionary

This dictionary records the current reported definitions and values. Values are from completed SQL outputs, original working documents and supplied visual summaries. Any item marked **Power BI sign-off check** must be reconciled against the existing completed SQL output before its DAX measure is approved.

## Project 1: Olist E-commerce

| KPI | Current definition | Reported value | Grain / denominator | Important caveat |
|---|---|---:|---|---|
| Orders placed | Count of distinct `order_id` in orders | 99,441 | Order | Dataset period is 2016-09-04 to 2018-10-17 |
| Delivered orders | Count of orders with `order_status = 'delivered'` | 96,478 (97.02%) | Order / 99,441 orders placed | Not the same as delivered orders with valid delivery dates |
| Delivered orders with valid dates | Delivered-status orders with actual delivery and estimated delivery dates required by delivery query | 96,470 | Eligible delivered order | Eight delivered-status orders lack an actual delivery timestamp and are excluded from delivery-duration/on-time calculations |
| Delivered item GMV (BRL) | Sum of order-item `price` for delivered orders | R$13,221,498.11 (R$13.22M) | Delivered order-item rows | Freight excluded; not net revenue, seller earnings or profit |
| Delivered freight value (BRL) | Sum of `freight_value` for delivered orders | R$2,198,275.64 | Delivered order-item rows | Keep separate from GMV; not a profit or margin measure |
| Delivered item AOV (BRL) | Delivered item GMV divided by delivered orders with item rows | R$137.04 | Delivered orders with item records; reported population is 96,478 | Item value only; freight excluded. Numerator and denominator must use the same population |
| Monthly GMV | Monthly item-value metric from completed sales analysis | Peak R$1,003,862.14 in Nov 2017 | Month | Jan–Aug 2018 ranged approximately R$837.9K–R$993.6K. Partial months must be flagged. The SQL exposes all-status and delivered-only expressions; select and label the exact series/filter in Power BI rather than assuming it equals delivered-only GMV |
| Payment-method value share | `SUM(payment_value)` by `payment_type` divided by total recorded payment value | Credit Card 73.6%; Boleto 19.2%; Voucher 5.2%; Debit Card 1.9%; Other 0.1% | Payment value | Rounded shares from supplied visual; not a share of orders/customers. One order can have multiple payment rows/types |
| On-time delivery rate — calendar date | Actual delivery calendar date on or before estimated calendar date | 93.23% | 89,936 / 96,470 eligible delivered orders (88,644 early + 1,292 on estimated date) | Agreed delivery dashboard KPI; same-calendar-date delivery counts on time |
| On-time delivery rate — timestamp comparison | Actual delivery timestamp on or before estimated delivery timestamp | 91.89% | Eligible rows in executive SQL timestamp comparison | Keep separate and label explicitly; do not mix with 93.23% calendar-date KPI |
| Late deliveries | Eligible delivered orders delivered after estimated calendar date | 6,534 (6.77%) | 6,534 / 96,470 eligible delivered orders | Descriptive operational metric; not a causal explanation |
| Average delivery time | Average elapsed calendar days from purchase to customer delivery | 12.56 days | 96,470 valid delivery-date records | Missing/invalid delivery dates excluded; this is calendar elapsed time, not business days |
| Unique customers | Distinct `customer_unique_id` represented in customer analysis | 96,096 | Unique customer identity | Use `customer_unique_id` for person-level repeat analysis, not order-level `customer_id` |
| Repeat customers | Customers with more than one observed order in the completed analysis | 2,997 | Customer identity | Observed 2016–2018 period, not lifetime retention |
| Repeat-customer rate | Repeat customers divided by unique customers | 3.12% | 2,997 / 96,096 | Observed-period repeat rate; not lifetime retention or cohort retention |
| Order frequency — one order | Customers with exactly one observed order | 93,099 (96.88%) | Customer identity | Other bands: 2,745 with two orders, 203 with three, 30 with four and 19 with five or more |
| Repeat-customer delivered GMV | Delivered item GMV attributed to repeat customers | R$760,377.86 | Repeat-customer segment | Freight excluded |
| Customers in repeat segment with delivered GMV | Repeat customers contributing delivered item GMV | 2,979 | Repeat-customer segment | This is the denominator for the reported R$255.25 segment average, not all 2,997 repeat customers |
| Average delivered GMV per repeat customer with delivered GMV | Repeat segment delivered item GMV divided by repeat customers with delivered GMV | R$255.25 | R$760,377.86 / 2,979 | Denominator clarified in original `analysis_log.md`; do not divide by all 2,997 for this segment average |
| Average delivered GMV per one-time customer with delivered GMV | One-time segment delivered item GMV divided by one-time customers with delivered GMV | R$137.88 | R$12,461,120.25 / 90,379 | Use the same delivered-GMV eligibility approach as the repeat segment |
| Repeat vs one-time average GMV/customer | Repeat-segment average divided by one-time-segment average | 1.85x | R$255.25 / R$137.88 | Segment averages, not lifetime value or causal impact |
| Active sellers with delivered activity | Distinct sellers with at least one delivered order item | 2,970 | Seller | Seller-month rows are not unique sellers: 16,068 seller-month combinations versus 2,970 sellers |
| Top 10 seller GMV share | Delivered item GMV of top 10 sellers divided by total delivered item GMV | 13.27% | Seller ranking by delivered item GMV | Top five sellers: 7.71%; largest single seller: 1.72% |
| Seller-state delivered GMV | Delivered item GMV grouped by seller state | São Paulo: R$8.51M; 1,769 active sellers | Seller state | Do not confuse with customer-state GMV |
| Customer-state delivered GMV | Delivered item GMV grouped by customer state | SP R$5.07M; RJ R$1.76M; MG R$1.55M; RS R$0.73M; PR R$0.67M | Customer state | SP has 40,494 delivered orders. Customer-state and seller-state totals answer different questions |
| Product categories | Count of categories represented in delivered item analysis | 74 | Category | 1,537 delivered item lines lacked original category; 22 lacked English translation |
| Delivered item lines | Count of delivered order-item rows in category analysis | 110,197 | Order-item line | Do not describe this as unique orders or units unless quantity is separately aggregated |
| Top 10 category GMV share | Top 10 categories' delivered item GMV divided by total delivered item GMV | 62.43% | Category ranking | Top five contribute 39.83%; top 20 contribute 85.36% |
| Highest-GMV categories | Delivered item GMV by category | Health & Beauty R$1.23M; Watches & Gifts R$1.17M; Bed, Bath & Table R$1.02M; Sports & Leisure R$0.95M; Furniture Decor R$0.71M | Category | Rounded values from supplied visual summary |
| Bed, Bath & Table item lines | Delivered order-item lines in category | 10,953 (9.94%) | Order-item line | Highest item-line volume among categories in supplied summary |
| Freight-to-item-value ratio | Freight value divided by item price value within a category | Furniture Decor: 23.65% | Category | Freight burden proxy; not profit impact or carrier cost recovery |
| Reconciled orders | Matched orders where item price + freight equals recorded payment within R$0.01 | 98,362 / 98,665 (99.69%) | Orders with both item and payment records | Reconciliation tolerance is R$0.01 |
| Payment reconciliation exceptions | Matched orders with absolute difference greater than R$0.01 | 303 | 98,665 matched orders | 264 have payment above item + freight; 39 have item + freight above payment. Exceptions are not automatically losses/refunds/overcharges |
| Missing item records | Orders with no corresponding order-item rows | 775 | Orders | 603 unavailable, 164 canceled, 5 created, 2 invoiced and 1 shipped |
| Missing payment records | Orders with no corresponding payment rows | 1 | Orders | The identified exception is in delivered status |
| Missing both items and payments | Orders missing both linked records | 0 | Orders | Based on completed coverage query |
| Repeated review ID groups | `review_id` values appearing on multiple rows | 789 groups; 814 additional rows; max 3 rows per ID | Review ID | All observed repeated IDs span multiple orders; `(review_id, order_id)` duplicate groups = 0. Do not deduplicate on `review_id` alone |

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
- Always state the numerator and denominator for percentages.
- Separate delivered-status counts from valid-date delivery-eligible counts.
- Keep item GMV and freight separate; do not label GMV or AOV as profit or marketplace net revenue.
- Keep monthly all-status/eligible-status GMV distinct from delivered-only item GMV.
- Keep customer-state and seller-state geography separate.
- Label sample, synthetic and obfuscated data prominently.
- Do not infer causation from descriptive correlations.
- Preserve known KPI-definition differences; do not silently overwrite one metric with another.
