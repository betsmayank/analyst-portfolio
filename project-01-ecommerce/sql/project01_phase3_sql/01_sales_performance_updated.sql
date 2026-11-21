/*
Project 01: Olist Brazilian E-commerce Analytics
Analysis 1: Sales performance baseline

Database: olist_analytics
Schema: stg

Purpose
-------
This script establishes the main sales-performance baseline for the Olist
dataset. It contains four analyses:

1. Monthly order and delivered merchandise performance.
2. Top product categories by delivered item GMV.
3. Payment-method mix across recorded payment transactions.
4. Order-level reconciliation of item value + freight against payment value.

Metric definitions
------------------
- Item GMV: SUM(order_items.price). Freight is reported separately.
- Delivered item GMV: Item GMV for orders with order_status = 'delivered'.
- Delivered AOV: Delivered item GMV divided by delivered orders that have
  at least one item record. The numerator and denominator use the same
  eligible order population.
- Payment value: SUM(order_payments.payment_value). This is not automatically
  company revenue.
- Reconciliation difference: Item GMV + freight value - recorded payment value.
- Reconciliation tolerance: R$0.01.

Important implementation decisions
----------------------------------
- Order items and payments are aggregated separately to order level before
  joining. This prevents join fanout when an order has multiple item rows
  and multiple payment rows.
- Query 1 uses a LEFT JOIN so orders remain in the monthly order count even
  when they have no item records.
- Query 2 and Query 3 use delivered orders and all recorded payment rows,
  respectively. Their populations are different and should not be compared
  as if they were the same measure.
- Query 4 includes orders with both item and payment records, regardless
  of order status.
- Reconciliation differences are diagnostic. They are not automatically
  evidence of incorrect customer charges or financial errors.
- The dataset does not provide marketplace commission, operating costs,
  or sufficient information to calculate company profit.

Run each SELECT statement separately in pgAdmin if you want to inspect
each result grid.
*/


/* QUERY 1
   Monthly order and delivered merchandise performance.

   Grain: one row per purchase month.

   Includes:
   - All orders placed.
   - Delivered order count.
   - Item GMV across all statuses.
   - Delivered item GMV and freight.
   - Delivered AOV for delivered orders with item records.

   Note: delivered_orders counts all delivered-status orders. The AOV
   denominator is narrower: delivered orders with item records. This keeps
   the numerator and denominator aligned.
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

    COUNT(*) FILTER (
        WHERE o.order_status = 'delivered'
    ) AS delivered_orders,

    COALESCE(
        SUM(i.item_gmv),
        0
    )::numeric(14,2) AS item_gmv_all_statuses,

    COALESCE(
        SUM(i.item_gmv) FILTER (
            WHERE o.order_status = 'delivered'
        ),
        0
    )::numeric(14,2) AS delivered_item_gmv,

    COALESCE(
        SUM(i.freight_value) FILTER (
            WHERE o.order_status = 'delivered'
        ),
        0
    )::numeric(14,2) AS delivered_freight_value,

    ROUND(
        COALESCE(
            SUM(i.item_gmv) FILTER (
                WHERE o.order_status = 'delivered'
            ),
            0
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE o.order_status = 'delivered'
                  AND i.order_id IS NOT NULL
            ),
            0
        ),
        2
    ) AS delivered_aov_item_gmv

FROM stg.orders AS o

LEFT JOIN item_totals AS i
    ON o.order_id = i.order_id

GROUP BY
    DATE_TRUNC('month', o.order_purchase_timestamp)

ORDER BY
    purchase_month;


/* QUERY 2
   Top 15 product categories by delivered item GMV.

   Grain before ranking: one row per product category.

   Category translation may be missing for some products. The query retains
   the original Portuguese category name and uses an explicit fallback label.

   The percentage share denominator is total delivered item GMV across all
   categories represented in this query, not only the displayed top 15.
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
        100.0 * delivered_item_gmv
        / NULLIF(SUM(delivered_item_gmv) OVER (), 0),
        2
    ) AS share_of_delivered_item_gmv_pct

FROM category_sales

ORDER BY
    delivered_item_gmv DESC

LIMIT 15;


/* QUERY 3
   Payment-method mix.

   Grain: one row per payment_type.

   One order can have multiple payment rows and may use multiple payment
   types. Therefore payment-record count and distinct order count are both
   displayed.

   Scope: all recorded payment rows, regardless of order status.
   Average payment value is per payment record, not per order.
*/

SELECT
    payment_type,

    COUNT(*) AS payment_records,

    COUNT(DISTINCT order_id) AS distinct_orders,

    SUM(payment_value)::numeric(14,2) AS total_payment_value,

    ROUND(
        AVG(payment_value),
        2
    ) AS avg_payment_record_value,

    ROUND(
        100.0 * SUM(payment_value)
        / NULLIF(SUM(SUM(payment_value)) OVER (), 0),
        2
    ) AS share_of_payment_value_pct

FROM stg.order_payments

GROUP BY
    payment_type

ORDER BY
    total_payment_value DESC;


/* QUERY 4
   Order-level payment reconciliation.

   Expected order value for this comparison:
       item GMV + freight value

   Compare that amount with the total recorded payment value per order.

   Scope: orders with both item records and payment records, regardless
   of order status.

   A difference of up to R$0.01, inclusive, is treated as reconciled.

   Differences are diagnostic, not automatically errors. Vouchers,
   adjustments, payment behaviour, or differences in dataset definitions
   may explain some discrepancies.
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

        ABS(
            (i.item_gmv + i.freight_value) - p.payment_value
        ) AS absolute_difference

    FROM stg.orders AS o

    INNER JOIN item_totals AS i
        ON o.order_id = i.order_id

    INNER JOIN payment_totals AS p
        ON o.order_id = p.order_id
)

SELECT
    COUNT(*) AS orders_with_items_and_payments,

    COUNT(*) FILTER (
        WHERE absolute_difference <= 0.01
    ) AS orders_reconciled_within_1_cent,

    COUNT(*) FILTER (
        WHERE absolute_difference > 0.01
    ) AS orders_with_difference_over_1_cent,

    ROUND(
        AVG(absolute_difference),
        2
    ) AS average_absolute_difference,

    ROUND(
        MAX(absolute_difference),
        2
    ) AS maximum_absolute_difference

FROM reconciled;
