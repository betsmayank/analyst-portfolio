# Project 01 — Phase 4: Power BI Semantic Model and Dashboard

## Goal

Turn the seven completed SQL analyses into a clear, interactive Power BI report without duplicating SQL work. The model and measures must reproduce the completed SQL definitions, not silently reinterpret them.

## Step 1 — Connect Power BI Desktop to PostgreSQL

1. Open Power BI Desktop.
2. Select **Home → Get data → More**.
3. Search for **PostgreSQL database** under Database and select **Connect**.
4. Enter:
   - Server: `localhost:5432`
   - Database: `olist_analytics`
5. Select **Import** as the connectivity mode.
6. Choose Database authentication, username `postgres`, and the local PostgreSQL password. Do not place the password in a PBIX note, SQL script, README or GitHub repository.
7. In Navigator, expand the `stg` schema and select only:
   - `orders`
   - `order_items`
   - `customers`
   - `products`
   - `sellers`
   - `order_payments`
   - `order_reviews`
   - `product_category_name_translation`
8. Do not select any `raw` table. Keep `geolocation` out of the first model; state-level analysis is already supported by customer and seller state fields, and the geolocation table contains about one million rows.
9. Choose **Transform Data**, not Load, for the first checkpoint. Review the Navigator selection and column types before loading.

Power BI Desktop includes the Npgsql provider for its PostgreSQL connector in modern releases, so a separate provider installation should not normally be required. If the connector raises a provider-specific error, capture the full message before installing anything. Microsoft documents Import and DirectQuery support for the connector: https://learn.microsoft.com/en-us/power-query/connectors/postgresql and https://learn.microsoft.com/en-us/power-bi/connect-data/desktop-use-directquery.

## Step 2 — Review the selected tables in Power Query

- Confirm date/time columns are Date/Time, financial fields are Decimal Number or Fixed Decimal Number, counts/sequence values are Whole Number, and IDs/postal codes are Text.
- Do not remove rows just because a timestamp or product category is null. The SQL analysis has documented specific exclusions and missingness patterns.
- Keep query names readable (for example `stg_orders`, `stg_order_items`) or remove the schema prefix consistently. Do not rename columns unless the model documentation records the mapping.
- Preserve the distinction between source `customer_id` (order-level customer record) and `customer_unique_id` (person-level repeat analysis identifier).

## Step 3 — Build and validate the model

Use the existing staging grain and verify keys/cardinalities before accepting relationships:

- `orders[order_id]` → `order_items[order_id]` (one order to many item lines).
- `orders[order_id]` → `order_payments[order_id]` (one order to one or more payment rows).
- `orders[order_id]` → `order_reviews[order_id]` only after verifying order-side cardinality from the loaded model; review IDs repeat across orders and must not be used as a standalone unique key.
- `customers[customer_id]` → `orders[customer_id]` only after verifying uniqueness/cardinality on both sides. Use `customer_unique_id` for person-level repeat analysis.
- `products[product_id]` → `order_items[product_id]`.
- `sellers[seller_id]` → `order_items[seller_id]`.
- `product_category_name_translation[product_category_name]` → `products[product_category_name]` after confirming lookup-key uniqueness.
- Add a proper date table related actively to purchase date. Use explicit inactive relationships or separate role-playing date tables only if the report needs delivery/estimated date slicers.

Use single-direction filtering as the default. Avoid unnecessary many-to-many relationships. Keep order items and payments as separate fact-like tables: joining both detail tables directly can multiply values and inflate sums. `04_build_staging.sql` creates performance indexes, not primary/foreign-key constraints; validate cardinality in the Power BI model.

## Step 4 — DAX measures to implement

Create measures only after the model loads and relationships are checked. Start with:

- Orders Placed
- Delivered Orders
- Delivered Item GMV
- Delivered Freight Value
- Delivered Item AOV
- Unique Customers
- Repeat Customers
- Repeat Customer Rate
- One-Time Customers
- Customers with Delivered GMV — Repeat Segment
- Customers with Delivered GMV — One-Time Segment
- Average Delivered GMV per Repeat Customer with Delivered GMV
- Average Delivered GMV per One-Time Customer with Delivered GMV
- Average Delivery Days
- Calendar-Date On-Time Rate
- Timestamp-Level On-Time Rate (only if retained and labelled separately)
- Late Delivered Orders
- Active Sellers
- Top 10 Seller GMV Share
- Top 10 Category GMV Share
- Payment-Method Share of Payment Value
- Payment Reconciliation Exceptions (where the relevant precomputed SQL result/table is available)

Use the KPI dictionary for formulas, denominators and exclusions. Specific sign-off rules:

- Repeat rate uses 2,997 repeat customers / 96,096 unique customers = 3.12%.
- Repeat-segment average uses R$760,377.86 / 2,979 customers with delivered GMV = R$255.25.
- One-time segment average uses R$12,461,120.25 / 90,379 customers with delivered GMV = R$137.88.
- Calendar-date on-time is 93.23% (89,936 / 96,470), counting same-date delivery as on time. The separate 91.89% executive timestamp comparison must not be substituted.
- Monthly GMV must reproduce the exact completed SQL expression and status filter. The `01` sales query exposes more than one monthly item-value measure; the executive query is delivered-only.
- Payment method mix is based on `SUM(payment_value)` shares, not the number of rows/orders/customers.

## Step 5 — Report pages

1. **Executive Overview:** headline KPIs, delivered-only monthly GMV trend, customer-state summary, order-status and operational metrics.
2. **Sales & Product Performance:** monthly GMV with explicit metric/filter label, category ranking, category GMV concentration, item-line volume and freight-to-item-value ratio.
3. **Customer & Seller Performance:** one-time/repeat order frequency, repeat-customer segment averages with correct denominators, seller ranking/concentration and customer-state versus seller-state views.
4. **Delivery & Data Quality:** 12.56-day average delivery time, 93.23% calendar-date on-time rate, 6,534 late orders, state variation, missing-record coverage and 303 reconciliation exceptions.

## Step 6 — Reconciliation and publication

For every headline visual, compare the DAX result with its completed SQL output. Record the SQL value, DAX value, difference and pass/fail status in a reconciliation sheet. Capture report screenshots, save the PBIX under `project-01-ecommerce/powerbi/`, update the project README and findings memo, then commit and push to GitHub.

## First checkpoint for the project owner

Complete Step 1 only. Stop at the Navigator/Power Query view and send a screenshot showing the selected `stg` tables. Do not load `raw` tables or the large `geolocation` table. The model and DAX will be built after the table selection is verified.
