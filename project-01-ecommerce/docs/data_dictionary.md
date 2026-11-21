
# Data Dictionary

This document describes the datasets used in the Olist E-commerce Analytics project.

The project uses nine CSV datasets imported into PostgreSQL. The data is organised into raw and staging schemas.

## Source tables

| Table | Description |
|---|---|
| customers | Customer records and customer location information |
| geolocation | Geographic coordinates associated with Brazilian postal codes |
| order_items | Products included in each order, including price and freight |
| order_payments | Payment records associated with orders |
| order_reviews | Customer reviews and review-related information |
| orders | Order identifiers, purchase timestamps, delivery dates and order statuses |
| product_category_name_translation | Portuguese-to-English product category translations |
| products | Product attributes and category information |
| sellers | Seller records and location information |

## Database organisation

### Raw schema

Contains the source data imported from the original CSV files.

### Staging schema

Contains the transformed tables used for SQL analysis.

The staging layer provides a consistent starting point for data profiling, validation and analytical queries.

## Table relationships

The main relationships explored in this project include:

- Orders to order items: `order_id`
- Orders to payments: `order_id`
- Orders to reviews: `order_id`
- Orders to customers: `customer_id`
- Order items to products: `product_id`
- Order items to sellers: `seller_id`
- Products to category translations: `product_category_name`

## Notes

Column-level definitions, data types, primary keys and foreign-key validation will be documented after reviewing the actual PostgreSQL table structures.


---

# Phase 3 completion addendum — analytical fields, grains and relationships

**Added:** 2026-11-21. The source-table inventory and relationship notes above are retained. This section adds the staging fields and data types used by the completed analyses, based on `04_build_staging.sql`.

## Staging table grains and key fields

| Staging table | Grain | Important fields and PostgreSQL staging types | Analytical use |
|---|---|---|---|
| `stg.orders` | One row per `order_id` | `order_id TEXT`; `customer_id TEXT`; `order_status TEXT`; purchase/approval/carrier-delivery/customer-delivery/estimated-delivery timestamps as `TIMESTAMP` | Order counts, order status, purchase-month trends, delivery duration and on-time metrics |
| `stg.customers` | One row per source `customer_id` | `customer_id TEXT`; `customer_unique_id TEXT`; ZIP prefix/city/state as `TEXT` | Customer identity and customer-state reporting; use `customer_unique_id` for person-level repeat analysis |
| `stg.order_items` | One row per `order_id` + `order_item_id` | `order_id TEXT`; `order_item_id INTEGER`; `product_id TEXT`; `seller_id TEXT`; `shipping_limit_date TIMESTAMP`; `price NUMERIC(12,2)`; `freight_value NUMERIC(12,2)` | Item GMV, freight, category sales, seller sales and order-item line counts |
| `stg.order_payments` | One payment-sequence row per order/payment record | `order_id TEXT`; `payment_sequential INTEGER`; `payment_type TEXT`; `payment_installments INTEGER`; `payment_value NUMERIC(12,2)` | Payment-method value mix and order-level reconciliation |
| `stg.order_reviews` | One source review row; repeated `review_id` values can occur across orders | `review_id TEXT`; `order_id TEXT`; `review_score INTEGER`; comment fields `TEXT`; review timestamps `TIMESTAMP` | Review-score analysis and potential delivery/review comparisons |
| `stg.products` | One row per `product_id` | `product_id TEXT`; category `TEXT`; name/description lengths, photos, weight and dimensions as `INTEGER` | Product/category mapping and product attribute analysis |
| `stg.sellers` | One row per `seller_id` | `seller_id TEXT`; seller ZIP prefix, city and state as `TEXT` | Seller activity, seller-state GMV and geographic reporting |
| `stg.product_category_name_translation` | One row per translated category in the lookup | Portuguese and English category names as `TEXT` | Product category labels; original names remain available when a translation is missing |
| `stg.geolocation` | Multiple geolocation observations can exist per ZIP prefix | ZIP prefix/city/state as `TEXT`; latitude/longitude as `NUMERIC(12,8)` | Optional geographic enrichment; excluded from the first Power BI model due to approximately one million rows and non-unique ZIP prefixes |

## Key and relationship notes

- Identifiers and postal-code prefixes are stored as `TEXT`; they are labels/keys, not quantities. This preserves leading zeroes.
- `stg.order_items` has a validated composite row key `(order_id, order_item_id)` in the completed quality checks.
- `stg.order_payments` is at payment-row grain; an order can have multiple payment rows and multiple payment types.
- `stg.order_reviews` may repeat `review_id` across different orders. In the observed snapshot there are 789 repeated `review_id` groups, but zero duplicate `(review_id, order_id)` groups. Do not use `review_id` alone as a unique key.
- `stg.geolocation.geolocation_zip_code_prefix` is not unique. Do not create a one-to-one relationship on ZIP prefix without a separate deduplication/aggregation design.
- Main analytical join paths are `orders.order_id` to order items, payments and reviews; `orders.customer_id` to customers; `order_items.product_id` to products; `order_items.seller_id` to sellers; and product category name to the translation lookup.
- These are analytical join paths, not proof that PostgreSQL foreign-key constraints are enforced.

## Constraint and indexing note

`04_build_staging.sql` creates staging tables with `CREATE TABLE AS`, then creates indexes on frequently used join/filter columns. The script comments explicitly state that these are **performance indexes, not uniqueness claims**. It does not declare primary-key or foreign-key constraints. Uniqueness and referential-integrity checks were performed through the separate validation SQL. Power BI relationships must therefore be created only after confirming cardinality in the loaded model.

## KPI field mapping

| KPI / measure | Source fields | Grain and handling |
|---|---|---|
| Delivered item GMV | `orders.order_status`, `order_items.order_id`, `order_items.price` | Sum item price for delivered-status orders; freight excluded |
| Delivered freight | `orders.order_status`, `order_items.freight_value` | Sum freight for delivered-status order items; keep separate from GMV |
| Delivered item AOV | Delivered item GMV and count of delivered orders with item rows | Numerator and denominator must describe the same eligible delivered-order population; reported value R$137.04 |
| Monthly sales GMV | `orders.order_purchase_timestamp`, `orders.order_status`, `order_items.price` | Month from purchase timestamp; the completed SQL exposes different all-status and delivered-only expressions. Preserve the exact filter/column selected for each report series |
| Payment-method value share | `order_payments.payment_type`, `order_payments.payment_value` | Sum payment value by type divided by total payment value; not order or customer share |
| Reconciliation difference | `order_items.price`, `order_items.freight_value`, `order_payments.payment_value` | Aggregate items and payments separately to order level, then calculate item + freight − payment; tolerance R$0.01 |
| Repeat-customer rate | `customers.customer_unique_id`, `orders.order_id` | Repeat customers / unique customers; 2,997 / 96,096 = 3.12% in the observed period |
| Segment average delivered GMV | Customer unique ID, delivered order status, item price | Divide segment delivered item GMV only by customers within that segment who have delivered item GMV: repeat 2,979; one-time 90,379 |
| Delivery duration | Purchase and actual delivery timestamps | Calendar-day elapsed duration; only eligible delivered rows with required dates |
| Calendar-date on-time | Actual delivery date and estimated delivery date | Actual calendar date <= estimated calendar date; 93.23%, 89,936 / 96,470 |
| Timestamp-level on-time | Actual and estimated delivery timestamps | Timestamp comparison from executive SQL; reported 91.89%; keep separate from calendar-date rate |
