/*
Project 01: Olist Brazilian E-commerce Analytics
Purpose: Validate staging row counts, key uniqueness, required fields,
relationships, and basic business-rule ranges.
Run against database: olist_analytics
Run after 04_build_staging.sql.

Notes:
- duplicate_key_groups counts duplicated key groups, not duplicated rows.
- Repeated review_id values are an observed source pattern; (review_id, order_id) is the key check used here.
- geolocation_zip_code_prefix is intentionally non-unique in the source.
- order_reviews.review_id can repeat in this source snapshot; validate the composite (review_id, order_id) key instead.
- Some NULL timestamps are expected for orders that were not delivered/approved.
*/

WITH checks AS (
    -- Row counts: these should agree with the raw schema.
    SELECT 'row_count'::text AS check_group, 'customers'::text AS check_name,
           (SELECT COUNT(*) FROM stg.customers)::bigint AS record_count,
           'Compare with raw.customers; expected 99441.'::text AS interpretation
    UNION ALL SELECT 'row_count', 'orders', (SELECT COUNT(*) FROM stg.orders), 'Compare with raw.orders; expected 99441.'
    UNION ALL SELECT 'row_count', 'order_items', (SELECT COUNT(*) FROM stg.order_items), 'Compare with raw.order_items; expected 112650.'
    UNION ALL SELECT 'row_count', 'order_payments', (SELECT COUNT(*) FROM stg.order_payments), 'Compare with raw.order_payments; expected 103886.'
    UNION ALL SELECT 'row_count', 'order_reviews', (SELECT COUNT(*) FROM stg.order_reviews), 'Compare with raw.order_reviews; expected 99224.'
    UNION ALL SELECT 'row_count', 'products', (SELECT COUNT(*) FROM stg.products), 'Compare with raw.products; expected 32951.'
    UNION ALL SELECT 'row_count', 'sellers', (SELECT COUNT(*) FROM stg.sellers), 'Compare with raw.sellers; expected 3095.'
    UNION ALL SELECT 'row_count', 'geolocation', (SELECT COUNT(*) FROM stg.geolocation), 'Compare with raw.geolocation; expected 1000163.'
    UNION ALL SELECT 'row_count', 'category_translation', (SELECT COUNT(*) FROM stg.product_category_name_translation), 'Compare with raw translation table; expected 71.'

    -- Duplicate key groups. Expected zero for these selected identifiers.
    UNION ALL SELECT 'duplicate_key_groups', 'customers.customer_id',
        (SELECT COUNT(*) FROM (SELECT customer_id FROM stg.customers GROUP BY customer_id HAVING COUNT(*) > 1) d),
        'Expected zero; customer_id should identify one customer record.'
    UNION ALL SELECT 'duplicate_key_groups', 'orders.order_id',
        (SELECT COUNT(*) FROM (SELECT order_id FROM stg.orders GROUP BY order_id HAVING COUNT(*) > 1) d),
        'Expected zero; order_id should identify one order.'
    UNION ALL SELECT 'duplicate_key_groups', 'order_items.order_id + order_item_id',
        (SELECT COUNT(*) FROM (SELECT order_id, order_item_id FROM stg.order_items GROUP BY order_id, order_item_id HAVING COUNT(*) > 1) d),
        'Expected zero; the pair identifies an order line.'
    UNION ALL SELECT 'duplicate_key_groups', 'order_payments.order_id + payment_sequential',
        (SELECT COUNT(*) FROM (SELECT order_id, payment_sequential FROM stg.order_payments GROUP BY order_id, payment_sequential HAVING COUNT(*) > 1) d),
        'Expected zero; the pair identifies a payment sequence.'
    UNION ALL SELECT 'duplicate_key_groups', 'order_reviews.review_id + order_id',
        (SELECT COUNT(*) FROM (SELECT review_id, order_id FROM stg.order_reviews GROUP BY review_id, order_id HAVING COUNT(*) > 1) d),
        'Expected zero; this composite key identifies a review-order record in this source snapshot.'
    UNION ALL SELECT 'source_pattern', 'order_reviews repeated review_id groups',
        (SELECT COUNT(*) FROM (SELECT review_id FROM stg.order_reviews GROUP BY review_id HAVING COUNT(*) > 1) d),
        'Informational, not a failure. Repeated review_id values occur in the Olist source; do not delete rows using review_id alone.'
    UNION ALL SELECT 'duplicate_key_groups', 'products.product_id',
        (SELECT COUNT(*) FROM (SELECT product_id FROM stg.products GROUP BY product_id HAVING COUNT(*) > 1) d),
        'Expected zero; product_id should identify a product.'
    UNION ALL SELECT 'duplicate_key_groups', 'sellers.seller_id',
        (SELECT COUNT(*) FROM (SELECT seller_id FROM stg.sellers GROUP BY seller_id HAVING COUNT(*) > 1) d),
        'Expected zero; seller_id should identify a seller.'

    -- Null or blank critical identifiers.
    UNION ALL SELECT 'missing_required_values', 'customers.customer_id',
        (SELECT COUNT(*) FROM stg.customers WHERE customer_id IS NULL),
        'Expected zero.'
    UNION ALL SELECT 'missing_required_values', 'orders.order_id',
        (SELECT COUNT(*) FROM stg.orders WHERE order_id IS NULL),
        'Expected zero.'
    UNION ALL SELECT 'missing_required_values', 'orders.customer_id',
        (SELECT COUNT(*) FROM stg.orders WHERE customer_id IS NULL),
        'Expected zero.'
    UNION ALL SELECT 'missing_required_values', 'order_items.order_id',
        (SELECT COUNT(*) FROM stg.order_items WHERE order_id IS NULL),
        'Expected zero.'
    UNION ALL SELECT 'missing_required_values', 'order_items.product_id',
        (SELECT COUNT(*) FROM stg.order_items WHERE product_id IS NULL),
        'Expected zero.'

    -- Referential integrity: these should normally be zero.
    UNION ALL SELECT 'orphan_records', 'orders.customer_id not found in customers',
        (SELECT COUNT(*) FROM stg.orders o LEFT JOIN stg.customers c ON c.customer_id = o.customer_id WHERE c.customer_id IS NULL),
        'Expected zero; every order should map to a customer.'
    UNION ALL SELECT 'orphan_records', 'order_items.order_id not found in orders',
        (SELECT COUNT(*) FROM stg.order_items i LEFT JOIN stg.orders o ON o.order_id = i.order_id WHERE o.order_id IS NULL),
        'Expected zero.'
    UNION ALL SELECT 'orphan_records', 'order_items.product_id not found in products',
        (SELECT COUNT(*) FROM stg.order_items i LEFT JOIN stg.products p ON p.product_id = i.product_id WHERE p.product_id IS NULL),
        'Expected zero.'
    UNION ALL SELECT 'orphan_records', 'order_items.seller_id not found in sellers',
        (SELECT COUNT(*) FROM stg.order_items i LEFT JOIN stg.sellers s ON s.seller_id = i.seller_id WHERE s.seller_id IS NULL),
        'Expected zero.'
    UNION ALL SELECT 'orphan_records', 'order_payments.order_id not found in orders',
        (SELECT COUNT(*) FROM stg.order_payments p LEFT JOIN stg.orders o ON o.order_id = p.order_id WHERE o.order_id IS NULL),
        'Expected zero.'
    UNION ALL SELECT 'orphan_records', 'order_reviews.order_id not found in orders',
        (SELECT COUNT(*) FROM stg.order_reviews r LEFT JOIN stg.orders o ON o.order_id = r.order_id WHERE o.order_id IS NULL),
        'Expected zero.'

    -- Basic numeric/business-rule checks.
    UNION ALL SELECT 'invalid_values', 'order_items negative price or freight',
        (SELECT COUNT(*) FROM stg.order_items WHERE price < 0 OR freight_value < 0),
        'Expected zero.'
    UNION ALL SELECT 'invalid_values', 'order_payments negative payment_value',
        (SELECT COUNT(*) FROM stg.order_payments WHERE payment_value < 0),
        'Expected zero.'
    UNION ALL SELECT 'invalid_values', 'order_reviews review_score outside 1 to 5',
        (SELECT COUNT(*) FROM stg.order_reviews WHERE review_score NOT BETWEEN 1 AND 5),
        'Expected zero; NULL scores are not counted by this condition.'
    UNION ALL SELECT 'invalid_values', 'orders delivered before purchase',
        (SELECT COUNT(*) FROM stg.orders WHERE order_delivered_customer_date < order_purchase_timestamp),
        'Expected zero; NULL delivery dates are excluded naturally.'
)
SELECT check_group, check_name, record_count, interpretation
FROM checks
ORDER BY check_group, check_name;
