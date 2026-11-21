
# Project Methodology

## 1. Project overview

This project analyses the Olist Brazilian e-commerce dataset to explore sales performance, order behaviour, product categories, payment activity and data quality.

PostgreSQL is used for data preparation and SQL analysis. Power BI will be used to develop interactive reports and visualise the findings.

## 2. Data source

The project uses nine CSV datasets from the Olist e-commerce dataset.

The source files contain information about customers, orders, products, sellers, payments, reviews and geolocation.

## 3. Data ingestion

The CSV files were imported into PostgreSQL.

The original datasets were stored in the `raw` schema, keeping the imported source data separate from subsequent transformations.

## 4. Data preparation

A separate `stg` schema was created for staging tables.

SQL scripts were used to create and validate the staging layer. This provides a structured foundation for subsequent analysis.

## 5. Data profiling and validation

Initial investigations included:

- Checking order volumes and status distribution.
- Reviewing the date range covered by the dataset.
- Investigating repeated review identifiers.
- Identifying orders without item or payment records.
- Comparing item values and freight charges against recorded payments.

Findings and relevant limitations are recorded in the project's data quality log.

## 6. Exploratory and business analysis

SQL queries are used to investigate:

- Monthly sales performance.
- Product category performance.
- Payment method distribution.
- Order-level payment reconciliation.

Further analysis will be added as the project develops.

## 7. Reporting and visualisation

Power BI will be used to present the validated analytical results through interactive dashboards.

The reporting layer will focus on relevant business metrics, trends and findings.

## 8. Documentation and reproducibility

SQL scripts, data definitions, investigation results and analytical decisions are maintained alongside the project.

This makes the analysis easier to review, understand and reproduce.


---

# Phase 3 completion addendum — analytical method and BI controls

**Added:** 2026-11-21. The methodology decisions above are retained. This section records how the completed seven-analysis phase applied those decisions and how they carry into Power BI.

## 9. ELT preparation pattern

The project followed an ELT-style workflow:

1. **Extract:** Download the nine public Olist CSV source files.
2. **Load:** Import source columns into PostgreSQL `raw` tables, initially as text, retaining source values.
3. **Transform:** Build typed `stg` tables inside PostgreSQL from `raw`, converting date/time, numeric and integer fields while keeping IDs and postal codes as text.

The raw layer remains the preserved source landing area. Staging transformations are repeatable and do not modify raw data. The staging build creates indexes for performance; these indexes are not uniqueness constraints.

## 10. Grain-first analysis and join control

- `stg.orders` is order-grain.
- `stg.order_items` is order-item-line grain.
- `stg.order_payments` is payment-record grain.
- `stg.order_reviews` is review-row grain; review IDs can repeat across multiple orders.
- Customer analysis groups by `customer_unique_id`; order-level `customer_id` is not the person-level repeat key.
- Seller analysis counts seller-order combinations where appropriate; one customer order can include multiple sellers.
- Category analysis counts delivered item lines; those rows are not automatically units or unique orders.
- Before joining item and payment data, each is aggregated to order grain separately. This avoids fanout from multiple item and payment rows multiplying totals.

## 11. Data-quality decision rules

- Reconcile row counts across raw and staging tables before analysis.
- Test uniqueness at the correct grain: `(order_id, order_item_id)` for item lines and `(review_id, order_id)` for review-order pairs in this source snapshot.
- Do not deduplicate repeated `review_id` values alone.
- Treat missing item/payment records as status-aware exceptions, not automatic invalid rows.
- Use R$0.01 as the documented payment reconciliation tolerance. Exceptions require investigation; they are not proof of financial error.
- Keep the eight delivered-status orders missing actual delivery timestamps out of delivery-duration/on-time calculations, but retain all 96,478 delivered-status orders in delivered-order reporting.
- Keep the six non-delivered-status orders with a delivery timestamp visible as source anomalies.
- Retain products/items with missing original categories or missing English translations and disclose the classification gap.

## 12. Metric definitions and comparison rules

- **Item GMV:** sum of item `price`; freight is separate.
- **Delivered item GMV:** sum of item `price` for orders whose status is `delivered`.
- **Delivered item AOV:** delivered item GMV divided by delivered orders with item rows (reported R$137.04).
- **Payment-method mix:** share of total recorded `payment_value` by `payment_type`, not share of payment records/orders/customers.
- **Payment reconciliation:** item GMV + freight − recorded payment value; order item and payment records are aggregated separately first.
- **Repeat-customer rate:** 2,997 repeat customers / 96,096 unique customers = 3.12% over the observed dataset period.
- **Repeat segment average delivered GMV:** R$760,377.86 / 2,979 repeat customers with delivered GMV = R$255.25. One-time segment average = R$12,461,120.25 / 90,379 = R$137.88. This resolves the apparent difference from dividing by all 2,997 repeat customers.
- **Calendar-date on-time rate:** actual delivery date on or before estimated delivery date; 93.23% (89,936 / 96,470). Same-calendar-date delivery is counted on time.
- **Timestamp-level on-time rate:** separate executive SQL comparison of actual timestamp to estimated timestamp; reported 91.89%. It must remain explicitly labelled and must not replace the calendar-date rate.
- **Monthly GMV:** retain the exact source SQL expression/status filter. The monthly analysis and executive delivered-only GMV are not automatically interchangeable.

## 13. Descriptive interpretation and limits

The seven completed analyses are descriptive. They identify historical patterns and exception concentrations but do not prove causes. The data does not contain marketplace commission, operating costs, product costs or sufficient data to calculate profit or net revenue. Observed repeat purchase is not lifetime retention. State/category/seller comparisons are not causal. Payment differences are not automatically losses, refunds or overcharges. The dataset covers anonymised Brazilian marketplace activity from 2016–2018 and is not evidence of current performance in another market.

## 14. Power BI implementation method

- Connect to PostgreSQL database `olist_analytics` in Import mode.
- Select the eight `stg` tables used for the first model: orders, order_items, customers, products, sellers, order_payments, order_reviews and product_category_name_translation. Keep `raw` out of the model; keep million-row `stg.geolocation` in PostgreSQL for the first version unless a specific report requirement justifies it.
- Preserve existing source grain. Keep item and payment fact-like tables separate; avoid flattening them together.
- Verify key uniqueness/cardinality before creating relationships. Use single-direction filtering as the default and avoid unnecessary many-to-many relationships.
- Add a date table with an active purchase-date relationship. Add role-playing/inactive date relationships only if delivery/estimated-date slicers are required.
- Build DAX from the KPI dictionary with explicit numerator, denominator, grain, status/date filters and exclusions.
- Reconcile each headline DAX measure to the existing completed SQL outputs before sign-off. Do not create duplicate SQL analyses; the seven existing scripts remain unchanged.
