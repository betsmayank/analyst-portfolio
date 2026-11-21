# Project 01 — Phase 2: PostgreSQL raw import guide

## 1. Create the database

In pgAdmin 4, connect to PostgreSQL 18. Right-click **Databases** → **Create** → **Database**. Set the database name to `olist_analytics`, owner to `postgres`, then Save.

## 2. Create the raw tables

Select `olist_analytics`, open **Tools → Query Tool**, open and run `project-01-ecommerce/sql/01_create_raw_tables.sql`.

## 3. Import each CSV

For each table listed below, expand **Schemas → raw → Tables**, right-click the table, and choose **Import/Export Data**. Choose **Import** and set:

- Filename: the matching CSV in `project-01-ecommerce/data/raw/`
- Format: `csv`
- Encoding: `UTF8`
- Header: `Yes`
- Delimiter: `,`
- Quote: `"`
- Escape: `"`

Keep the other options at their defaults. Start the import and confirm the success message before moving to the next table.

| CSV file | Target table |
|---|---|
| `olist_customers_dataset.csv` | `raw.customers` |
| `olist_geolocation_dataset.csv` | `raw.geolocation` |
| `olist_order_items_dataset.csv` | `raw.order_items` |
| `olist_order_payments_dataset.csv` | `raw.order_payments` |
| `olist_order_reviews_dataset.csv` | `raw.order_reviews` |
| `olist_orders_dataset.csv` | `raw.orders` |
| `olist_products_dataset.csv` | `raw.products` |
| `olist_sellers_dataset.csv` | `raw.sellers` |
| `product_category_name_translation.csv` | `raw.product_category_name_translation` |

Import into the empty `raw` tables only once. If an import fails, stop and inspect the error rather than repeatedly importing into the same table, which would create duplicate rows.

## 4. Validate the import

Open `project-01-ecommerce/sql/02_validate_imports.sql` in Query Tool and execute it. Save or screenshot the results from sections 1–4 and send them for review.

## Why raw columns are TEXT

The raw layer preserves the source file as received. Dates, numeric values, blank fields, and malformed values can then be checked explicitly before creating typed analytical tables. This is a deliberate staging practice, not the final analytical data model.
