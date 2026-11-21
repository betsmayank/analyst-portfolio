/*
Project 01: Olist Brazilian E-commerce Analytics
Purpose: Convert imported raw TEXT columns into typed staging tables.
Run against database: olist_analytics
Source schema: raw
Target schema: stg

Safe to rerun: this script replaces only the stg schema's nine project tables.
It does not modify or delete anything in raw.*.
*/

BEGIN;

CREATE SCHEMA IF NOT EXISTS stg;

DROP TABLE IF EXISTS stg.product_category_name_translation;
DROP TABLE IF EXISTS stg.geolocation;
DROP TABLE IF EXISTS stg.sellers;
DROP TABLE IF EXISTS stg.products;
DROP TABLE IF EXISTS stg.order_reviews;
DROP TABLE IF EXISTS stg.order_payments;
DROP TABLE IF EXISTS stg.order_items;
DROP TABLE IF EXISTS stg.orders;
DROP TABLE IF EXISTS stg.customers;

-- Keep identifiers and postal-code prefixes as TEXT. They are labels/keys,
-- not quantities; converting them to numbers could remove leading zeroes.
CREATE TABLE stg.customers AS
SELECT
    NULLIF(BTRIM(customer_id), '') AS customer_id,
    NULLIF(BTRIM(customer_unique_id), '') AS customer_unique_id,
    NULLIF(BTRIM(customer_zip_code_prefix), '') AS customer_zip_code_prefix,
    NULLIF(BTRIM(customer_city), '') AS customer_city,
    NULLIF(BTRIM(customer_state), '') AS customer_state
FROM raw.customers;

CREATE TABLE stg.orders AS
SELECT
    NULLIF(BTRIM(order_id), '') AS order_id,
    NULLIF(BTRIM(customer_id), '') AS customer_id,
    NULLIF(BTRIM(order_status), '') AS order_status,
    NULLIF(BTRIM(order_purchase_timestamp), '')::timestamp AS order_purchase_timestamp,
    NULLIF(BTRIM(order_approved_at), '')::timestamp AS order_approved_at,
    NULLIF(BTRIM(order_delivered_carrier_date), '')::timestamp AS order_delivered_carrier_date,
    NULLIF(BTRIM(order_delivered_customer_date), '')::timestamp AS order_delivered_customer_date,
    NULLIF(BTRIM(order_estimated_delivery_date), '')::timestamp AS order_estimated_delivery_date
FROM raw.orders;

CREATE TABLE stg.order_items AS
SELECT
    NULLIF(BTRIM(order_id), '') AS order_id,
    NULLIF(BTRIM(order_item_id), '')::integer AS order_item_id,
    NULLIF(BTRIM(product_id), '') AS product_id,
    NULLIF(BTRIM(seller_id), '') AS seller_id,
    NULLIF(BTRIM(shipping_limit_date), '')::timestamp AS shipping_limit_date,
    NULLIF(BTRIM(price), '')::numeric(12,2) AS price,
    NULLIF(BTRIM(freight_value), '')::numeric(12,2) AS freight_value
FROM raw.order_items;

CREATE TABLE stg.order_payments AS
SELECT
    NULLIF(BTRIM(order_id), '') AS order_id,
    NULLIF(BTRIM(payment_sequential), '')::integer AS payment_sequential,
    NULLIF(BTRIM(payment_type), '') AS payment_type,
    NULLIF(BTRIM(payment_installments), '')::integer AS payment_installments,
    NULLIF(BTRIM(payment_value), '')::numeric(12,2) AS payment_value
FROM raw.order_payments;

CREATE TABLE stg.order_reviews AS
SELECT
    NULLIF(BTRIM(review_id), '') AS review_id,
    NULLIF(BTRIM(order_id), '') AS order_id,
    NULLIF(BTRIM(review_score), '')::integer AS review_score,
    NULLIF(BTRIM(review_comment_title), '') AS review_comment_title,
    NULLIF(BTRIM(review_comment_message), '') AS review_comment_message,
    NULLIF(BTRIM(review_creation_date), '')::timestamp AS review_creation_date,
    NULLIF(BTRIM(review_answer_timestamp), '')::timestamp AS review_answer_timestamp
FROM raw.order_reviews;

CREATE TABLE stg.products AS
SELECT
    NULLIF(BTRIM(product_id), '') AS product_id,
    NULLIF(BTRIM(product_category_name), '') AS product_category_name,
    NULLIF(BTRIM(product_name_lenght), '')::integer AS product_name_length,
    NULLIF(BTRIM(product_description_lenght), '')::integer AS product_description_length,
    NULLIF(BTRIM(product_photos_qty), '')::integer AS product_photos_qty,
    NULLIF(BTRIM(product_weight_g), '')::integer AS product_weight_g,
    NULLIF(BTRIM(product_length_cm), '')::integer AS product_length_cm,
    NULLIF(BTRIM(product_height_cm), '')::integer AS product_height_cm,
    NULLIF(BTRIM(product_width_cm), '')::integer AS product_width_cm
FROM raw.products;

CREATE TABLE stg.sellers AS
SELECT
    NULLIF(BTRIM(seller_id), '') AS seller_id,
    NULLIF(BTRIM(seller_zip_code_prefix), '') AS seller_zip_code_prefix,
    NULLIF(BTRIM(seller_city), '') AS seller_city,
    NULLIF(BTRIM(seller_state), '') AS seller_state
FROM raw.sellers;

CREATE TABLE stg.geolocation AS
SELECT
    NULLIF(BTRIM(geolocation_zip_code_prefix), '') AS geolocation_zip_code_prefix,
    NULLIF(BTRIM(geolocation_lat), '')::numeric(12,8) AS geolocation_lat,
    NULLIF(BTRIM(geolocation_lng), '')::numeric(12,8) AS geolocation_lng,
    NULLIF(BTRIM(geolocation_city), '') AS geolocation_city,
    NULLIF(BTRIM(geolocation_state), '') AS geolocation_state
FROM raw.geolocation;

CREATE TABLE stg.product_category_name_translation AS
SELECT
    NULLIF(BTRIM(product_category_name), '') AS product_category_name,
    NULLIF(BTRIM(product_category_name_english), '') AS product_category_name_english
FROM raw.product_category_name_translation;

-- Index common join keys. These are performance indexes, not uniqueness claims.
CREATE INDEX idx_stg_customers_customer_id ON stg.customers(customer_id);
CREATE INDEX idx_stg_customers_unique_id ON stg.customers(customer_unique_id);
CREATE INDEX idx_stg_orders_order_id ON stg.orders(order_id);
CREATE INDEX idx_stg_orders_customer_id ON stg.orders(customer_id);
CREATE INDEX idx_stg_orders_purchase_timestamp ON stg.orders(order_purchase_timestamp);
CREATE INDEX idx_stg_order_items_order_id ON stg.order_items(order_id);
CREATE INDEX idx_stg_order_items_product_id ON stg.order_items(product_id);
CREATE INDEX idx_stg_order_items_seller_id ON stg.order_items(seller_id);
CREATE INDEX idx_stg_order_payments_order_id ON stg.order_payments(order_id);
CREATE INDEX idx_stg_order_reviews_order_id ON stg.order_reviews(order_id);
CREATE INDEX idx_stg_products_product_id ON stg.products(product_id);
CREATE INDEX idx_stg_sellers_seller_id ON stg.sellers(seller_id);
CREATE INDEX idx_stg_geolocation_zip ON stg.geolocation(geolocation_zip_code_prefix);
CREATE INDEX idx_stg_translation_category ON stg.product_category_name_translation(product_category_name);

ANALYZE stg.customers;
ANALYZE stg.orders;
ANALYZE stg.order_items;
ANALYZE stg.order_payments;
ANALYZE stg.order_reviews;
ANALYZE stg.products;
ANALYZE stg.sellers;
ANALYZE stg.geolocation;
ANALYZE stg.product_category_name_translation;

COMMIT;

-- Staging table row counts. They should match the raw table row counts.
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM stg.customers
UNION ALL SELECT 'orders', COUNT(*) FROM stg.orders
UNION ALL SELECT 'order_items', COUNT(*) FROM stg.order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM stg.order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM stg.order_reviews
UNION ALL SELECT 'products', COUNT(*) FROM stg.products
UNION ALL SELECT 'sellers', COUNT(*) FROM stg.sellers
UNION ALL SELECT 'geolocation', COUNT(*) FROM stg.geolocation
UNION ALL SELECT 'product_category_name_translation', COUNT(*) FROM stg.product_category_name_translation
ORDER BY table_name;
