/*
Project 01: Olist Brazilian E-commerce Analytics
Purpose: Validate that all nine CSVs were imported and inspect key integrity.

Run only after importing all nine files into the matching raw.* tables.
Expected row counts are useful reference points, not pass/fail constraints;
small differences can occur if a different dataset release is downloaded.
*/

-- 1) Row counts: all nine source tables should return a non-zero count.
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM raw.customers
UNION ALL SELECT 'geolocation', COUNT(*) FROM raw.geolocation
UNION ALL SELECT 'order_items', COUNT(*) FROM raw.order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM raw.order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM raw.order_reviews
UNION ALL SELECT 'orders', COUNT(*) FROM raw.orders
UNION ALL SELECT 'products', COUNT(*) FROM raw.products
UNION ALL SELECT 'sellers', COUNT(*) FROM raw.sellers
UNION ALL SELECT 'product_category_name_translation', COUNT(*) FROM raw.product_category_name_translation
ORDER BY table_name;

-- 2) Blank/null business identifiers. Ideally these counts are zero.
SELECT 'customers.customer_id' AS field_name,
       COUNT(*) FILTER (WHERE NULLIF(BTRIM(customer_id), '') IS NULL) AS blank_count
FROM raw.customers
UNION ALL
SELECT 'orders.order_id', COUNT(*) FILTER (WHERE NULLIF(BTRIM(order_id), '') IS NULL)
FROM raw.orders
UNION ALL
SELECT 'orders.customer_id', COUNT(*) FILTER (WHERE NULLIF(BTRIM(customer_id), '') IS NULL)
FROM raw.orders
UNION ALL
SELECT 'order_items.order_id', COUNT(*) FILTER (WHERE NULLIF(BTRIM(order_id), '') IS NULL)
FROM raw.order_items
UNION ALL
SELECT 'order_items.product_id', COUNT(*) FILTER (WHERE NULLIF(BTRIM(product_id), '') IS NULL)
FROM raw.order_items
UNION ALL
SELECT 'order_items.seller_id', COUNT(*) FILTER (WHERE NULLIF(BTRIM(seller_id), '') IS NULL)
FROM raw.order_items
ORDER BY field_name;

-- 3) Duplicate-key groups. These are diagnostic counts, not automatic deletions.
SELECT 'customers.customer_id' AS key_name, COUNT(*) AS duplicate_groups
FROM (SELECT customer_id FROM raw.customers GROUP BY customer_id HAVING COUNT(*) > 1) d
UNION ALL
SELECT 'orders.order_id', COUNT(*)
FROM (SELECT order_id FROM raw.orders GROUP BY order_id HAVING COUNT(*) > 1) d
UNION ALL
SELECT 'order_items(order_id, order_item_id)', COUNT(*)
FROM (SELECT order_id, order_item_id FROM raw.order_items GROUP BY order_id, order_item_id HAVING COUNT(*) > 1) d
UNION ALL
SELECT 'order_payments(order_id, payment_sequential)', COUNT(*)
FROM (SELECT order_id, payment_sequential FROM raw.order_payments GROUP BY order_id, payment_sequential HAVING COUNT(*) > 1) d
UNION ALL
SELECT 'products.product_id', COUNT(*)
FROM (SELECT product_id FROM raw.products GROUP BY product_id HAVING COUNT(*) > 1) d
UNION ALL
SELECT 'sellers.seller_id', COUNT(*)
FROM (SELECT seller_id FROM raw.sellers GROUP BY seller_id HAVING COUNT(*) > 1) d
UNION ALL
SELECT 'product_category_name_translation.product_category_name', COUNT(*)
FROM (SELECT product_category_name FROM raw.product_category_name_translation GROUP BY product_category_name HAVING COUNT(*) > 1) d
ORDER BY key_name;

-- 4) Orphan relationships. An orphan is a child record with no matching parent.
SELECT 'orders -> customers' AS relationship, COUNT(*) AS orphan_rows
FROM raw.orders o
LEFT JOIN raw.customers c ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL
UNION ALL
SELECT 'order_items -> orders', COUNT(*)
FROM raw.order_items i
LEFT JOIN raw.orders o ON o.order_id = i.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'order_items -> products', COUNT(*)
FROM raw.order_items i
LEFT JOIN raw.products p ON p.product_id = i.product_id
WHERE p.product_id IS NULL
UNION ALL
SELECT 'order_items -> sellers', COUNT(*)
FROM raw.order_items i
LEFT JOIN raw.sellers s ON s.seller_id = i.seller_id
WHERE s.seller_id IS NULL
UNION ALL
SELECT 'order_payments -> orders', COUNT(*)
FROM raw.order_payments p
LEFT JOIN raw.orders o ON o.order_id = p.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'order_reviews -> orders', COUNT(*)
FROM raw.order_reviews r
LEFT JOIN raw.orders o ON o.order_id = r.order_id
WHERE o.order_id IS NULL
ORDER BY relationship;

-- 5) Inspect observed order statuses and review scores; do not assume values.
SELECT order_status, COUNT(*) AS orders
FROM raw.orders
GROUP BY order_status
ORDER BY orders DESC, order_status;

SELECT review_score, COUNT(*) AS review_rows
FROM raw.order_reviews
GROUP BY review_score
ORDER BY review_score;

-- 6) Check blank values in important date fields before type conversion.
SELECT 'order_purchase_timestamp' AS field_name,
       COUNT(*) FILTER (WHERE NULLIF(BTRIM(order_purchase_timestamp), '') IS NULL) AS blank_count
FROM raw.orders
UNION ALL
SELECT 'order_approved_at', COUNT(*) FILTER (WHERE NULLIF(BTRIM(order_approved_at), '') IS NULL)
FROM raw.orders
UNION ALL
SELECT 'order_delivered_customer_date', COUNT(*) FILTER (WHERE NULLIF(BTRIM(order_delivered_customer_date), '') IS NULL)
FROM raw.orders
UNION ALL
SELECT 'order_estimated_delivery_date', COUNT(*) FILTER (WHERE NULLIF(BTRIM(order_estimated_delivery_date), '') IS NULL)
FROM raw.orders
ORDER BY field_name;
