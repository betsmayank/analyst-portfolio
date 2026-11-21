# Project 1 Requirements: E-commerce Business Performance & Customer Experience

## Business case

An online marketplace operations team wants to understand how product sales, customer repeat purchasing, seller/category mix, delivery performance and customer reviews relate. The analyst must identify where management should investigate operational problems and which product or seller segments deserve attention.

## Stakeholders

- Head of Marketplace Operations: delivery performance and service quality.
- Commercial Manager: product GMV, order mix and category performance.
- Customer Experience Manager: repeat purchasing, reviews and customer experience.
- Finance / Marketplace Performance Manager: payment reconciliation and reporting reliability.

## Decisions supported

1. Which product categories and seller/customer regions contribute the largest delivered item GMV?
2. How do monthly sales and delivered product GMV change over time?
3. What share of customers place more than one order in the observed period?
4. Where are late deliveries concentrated, and how do delivery metrics differ by geography?
5. How does seller contribution vary, and how concentrated is delivered GMV among sellers?
6. How do delivery performance and review scores relate? (Descriptive relationship only; no causal claim.)
7. Can item, freight and payment values be reconciled reliably enough for management reporting?
8. How is recorded payment value distributed across payment methods?

## In-scope data

Olist public tables: customers, orders, order items, order payments, order reviews, products, sellers, product category name translation and geolocation. The geolocation table was imported and retained in PostgreSQL; the first Power BI model can use customer/seller state fields without importing its approximately one-million-row table.

## Definitions and constraints

- Product GMV is the sum of item `price` for delivered orders. Freight is reported separately.
- GMV is not marketplace net revenue, seller earnings, profit or contribution margin.
- Delivered order count uses `order_status = 'delivered'`; delivery-duration/on-time metrics require valid purchase, actual-delivery and estimated-delivery dates and therefore use a smaller eligible denominator.
- Delivered item AOV in the executive snapshot is delivered item GMV divided by delivered orders that have item rows; freight is excluded.
- Repeat purchasing is measured using `customer_unique_id`, not `customer_id`. The completed analysis reports 2,997 repeat customers and a 3.12% repeat rate; delivered-GMV-per-customer segment averages use the narrower populations with delivered GMV (2,979 repeat and 90,379 one-time customers).
- Calendar-date on-time delivery is the agreed delivery dashboard KPI: actual delivery date on or before the estimated calendar date. The alternate 91.89% timestamp-level result must remain separately labelled if shown.
- Reviews are ordinal scores from 1 to 5. Correlation does not prove delivery delays caused a lower score.
- Reconciliation exceptions are differences between order-item value plus freight and recorded payments. They are investigation flags, not automatically losses, refunds or overcharges.
- Payment-method percentages refer to shares of total recorded payment value, not shares of orders or customers; one order may have multiple payment rows/types.
- The dataset represents an anonymised Brazilian marketplace sample from 2016–2018. It is not evidence of current performance in India or Europe.

## Functional requirements and implementation status

| Requirement | Status |
|---|---|
| Load nine source CSVs into PostgreSQL raw tables | Complete |
| Create typed staging tables | Complete |
| Profile row counts, nulls, duplicate keys and relationships | Complete for the completed validation scope |
| Create seven SQL analysis files | Complete, per supplied tracker |
| Document findings, data-quality issues, methodology and KPI definitions | Complete; original working documents retained and supplemented |
| Reconcile all reported KPI definitions for Power BI | Partially complete; repeat-segment denominator clarified; monthly series and two on-time definitions must remain distinct |
| Build Power BI model and report | Next |
| Reconcile headline dashboard KPIs against SQL | Next |
| Publish final README, screenshots, insight memo and PBIX reference in GitHub | Next |

## Acceptance criteria

- Every dashboard KPI has a written definition, grain, numerator/denominator and exclusions where relevant.
- Delivered-status denominators and valid-delivery-date denominators are never mixed without explanation.
- Calendar-date on-time rate (93.23%) and timestamp-level on-time rate (91.89%) remain separate and labelled.
- The repeat-customer rate uses 2,997 / 96,096; segment delivered-GMV averages use 2,979 repeat and 90,379 one-time customers with delivered GMV.
- Freight is not silently included in product GMV.
- Monthly GMV and delivered-only item GMV are not treated as interchangeable; preserve the exact completed SQL filter.
- No profit claim is made because cost and margin data are not provided.
- Existing SQL analysis is reused; no duplicate analysis scripts are created just to rebuild the same results.
- All findings use actual verified outputs, not assumed results.
