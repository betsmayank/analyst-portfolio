# Olist staging-layer setup

Run these scripts in the `olist_analytics` database after all nine CSV files have been imported into the `raw` schema.

## Files

- `project-01-ecommerce/sql/04_build_staging.sql`: creates typed tables in the `stg` schema, indexes common join keys, analyses the tables, and prints row counts.
- `project-01-ecommerce/sql/05_validate_staging.sql`: checks row counts, selected duplicate keys, missing critical identifiers, orphan relationships, and numeric ranges in one results grid.
- `project-01-ecommerce/sql/06_profile_orders.sql`: profiles order statuses and purchase-date coverage.

## Important design decisions

- The `raw` schema is preserved and never modified by these scripts.
- Identifiers and postal-code prefixes stay as text because they are keys/labels, not measures. This also preserves possible leading zeroes.
- Dates are stored as PostgreSQL `timestamp` values. The source does not provide timezone offsets, so this project does not invent them.
- Prices and payment values use `numeric(12,2)` to avoid floating-point rounding for currency.
- The source's misspelled column names `product_name_lenght` and `product_description_lenght` are renamed to `product_name_length` and `product_description_length` in staging.
- Geolocation ZIP prefixes are not unique. Do not add a uniqueness constraint to that field.
- No primary/foreign key constraints are added until the validation results are reviewed.

## Run in pgAdmin

1. In pgAdmin, select the `olist_analytics` database and open Query Tool.
2. Open `04_build_staging.sql` and execute it with F5.
3. Confirm the nine staging row counts match the corresponding raw counts.
4. Open `05_validate_staging.sql` and execute it with F5.
5. Open `06_profile_orders.sql` and execute its two SELECT statements to inspect order statuses and date coverage.
6. Save/export the results or capture screenshots for the project evidence.

The staging build script is safe to rerun: it drops and recreates only the nine named tables in `stg`. It does not delete source data in `raw`.
