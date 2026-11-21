/*
Project 01: Olist Brazilian E-commerce Analytics
Phase 3, Analysis 1: Sales performance baseline
Database: olist_analytics
Source: stg schema

Business questions:
1) How does completed (delivered-status) merchandise value trend by month?
2) Which product categories generate the most completed merchandise value?
3) Which payment methods account for the largest payment value?
4) Do order-item value plus freight reconcile to recorded payment value?

Metric definitions:
- Item GMV = SUM(order_items.price). Freight is shown separately.
- Delivered item GMV = item GMV for orders whose order_status = 'delivered'.
- Delivered AOV = delivered item GMV / delivered orders with item rows.
- Payment value = SUM(order_payments.payment_value); it is not automatically company revenue.
- This dataset does not include marketplace commission, operating costs, or profit.

Important implementation note:
Aggregate order items and payments separately to order level before joining.
This avoids fanout (multiplying values when an order has multiple items and payments).
Run each SELECT separately in pgAdmin if you want to inspect each result grid.
*/

/* QUERY 1: Monthly order and delivered merchandise performance.
   Delivered status is used for completed-order classification.
   Missing delivery timestamps do not remove an order from this sales metric;
   those timestamp exceptions are excluded only from delivery-time calculations.
*/
WITH item_totals AS (
    SELECT
        order_id,
        SUM(price) AS item_gmv,
        SUM(freight_value) AS freight_value,
        COUNT(*) AS item_lines
    FROM stg.order_items
    GROUP BY order_id
)
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)::date AS purchase_month,
    COUNT(*) AS orders_placed,
    COUNT(*) FILTER (WHERE o.order_status = 'delivered') AS delivered_orders,
    COALESCE(SUM(i.item_gmv), 0)::numeric(14,2) AS item_gmv_all_statuses,
    COALESCE(SUM(i.item_gmv) FILTER (WHERE o.order_status = 'delivered'), 0)::numeric(14,2)
        AS delivered_item_gmv,
    COALESCE(SUM(i.freight_value) FILTER (WHERE o.order_status = 'delivered'), 0)::numeric(14,2)
        AS delivered_freight_value,
    ROUND(
        COALESCE(SUM(i.item_gmv) FILTER (WHERE o.order_status = 'delivered'), 0)
        / NULLIF(COUNT(*) FILTER (WHERE o.order_status = 'delivered' AND i.order_id IS NOT NULL), 0),
        2
    ) AS delivered_aov_item_gmv
FROM stg.orders AS o
LEFT JOIN item_totals AS i
    ON o.order_id = i.order_id
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY purchase_month;


/* QUERY 2: Top 15 product categories by delivered item GMV.
   Category translation may be missing for some products, so retain the
   original category name and use an explicit fallback label.
*/
WITH category_sales AS (
    SELECT
        COALESCE(
            t.product_category_name_english,
            p.product_category_name,
            'unknown_or_uncategorized'
        ) AS product_category,
        COUNT(*) AS delivered_item_lines,
        COUNT(DISTINCT oi.order_id) AS delivered_orders,
        SUM(oi.price)::numeric(14,2) AS delivered_item_gmv
    FROM stg.order_items AS oi
    INNER JOIN stg.orders AS o
        ON oi.order_id = o.order_id
    LEFT JOIN stg.products AS p
        ON oi.product_id = p.product_id
    LEFT JOIN stg.product_category_name_translation AS t
        ON p.product_category_name = t.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY 1
)
SELECT
    product_category,
    delivered_item_lines,
    delivered_orders,
    delivered_item_gmv,
    ROUND(
        100.0 * delivered_item_gmv / NULLIF(SUM(delivered_item_gmv) OVER (), 0),
        2
    ) AS share_of_delivered_item_gmv_pct
FROM category_sales
ORDER BY delivered_item_gmv DESC
LIMIT 15;


/* QUERY 3: Payment-method mix.
   One order can have multiple payment rows and even multiple payment types.
   Therefore payment-row count and distinct order count are both displayed.
*/
SELECT
    payment_type,
    COUNT(*) AS payment_records,
    COUNT(DISTINCT order_id) AS distinct_orders,
    SUM(payment_value)::numeric(14,2) AS total_payment_value,
    ROUND(AVG(payment_value), 2) AS avg_payment_record_value,
    ROUND(
        100.0 * SUM(payment_value) / NULLIF(SUM(SUM(payment_value)) OVER (), 0),
        2
    ) AS share_of_payment_value_pct
FROM stg.order_payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;


/* QUERY 4: Order-level payment reconciliation.
   Compare item GMV + freight against recorded customer payment value.
   Differences are diagnostic, not automatically errors: vouchers, adjustments,
   and dataset-specific payment behaviour may explain some differences.
*/
WITH item_totals AS (
    SELECT
        order_id,
        SUM(price) AS item_gmv,
        SUM(freight_value) AS freight_value
    FROM stg.order_items
    GROUP BY order_id
),
payment_totals AS (
    SELECT
        order_id,
        SUM(payment_value) AS payment_value
    FROM stg.order_payments
    GROUP BY order_id
),
reconciled AS (
    SELECT
        o.order_id,
        o.order_status,
        i.item_gmv,
        i.freight_value,
        p.payment_value,
        (i.item_gmv + i.freight_value) AS item_plus_freight,
        ABS((i.item_gmv + i.freight_value) - p.payment_value) AS absolute_difference
    FROM stg.orders AS o
    INNER JOIN item_totals AS i
        ON o.order_id = i.order_id
    INNER JOIN payment_totals AS p
        ON o.order_id = p.order_id
)
SELECT
    COUNT(*) AS orders_with_items_and_payments,
    COUNT(*) FILTER (WHERE absolute_difference <= 0.01) AS orders_reconciled_within_1_cent,
    COUNT(*) FILTER (WHERE absolute_difference > 0.01) AS orders_with_difference_over_1_cent,
    ROUND(AVG(absolute_difference), 2) AS average_absolute_difference,
    ROUND(MAX(absolute_difference), 2) AS maximum_absolute_difference
FROM reconciled;
