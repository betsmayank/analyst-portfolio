/*
Project 01: Olist Brazilian E-commerce Analytics
Purpose: Profile order statuses and available purchase-date coverage.
Run after 04_build_staging.sql. Execute the two SELECT statements separately
if pgAdmin displays only the final result grid.
*/

-- 1) Order status distribution.
SELECT order_status, COUNT(*) AS order_count
FROM stg.orders
GROUP BY order_status
ORDER BY order_count DESC;

-- 2) Dataset coverage and delivered-order count.
SELECT
    MIN(order_purchase_timestamp) AS first_purchase_timestamp,
    MAX(order_purchase_timestamp) AS last_purchase_timestamp,
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NOT NULL) AS delivered_orders
FROM stg.orders;
