/*
Project 01: Olist Brazilian E-commerce Analytics
Phase 3, Analysis 6: Executive KPI overview
Database: olist_analytics
Schema: stg

Purpose
-------
Bring the main sales, customer, seller and delivery measures into a compact
executive view that can support the first page of the Power BI dashboard.

Queries
-------
1. Overall business KPI snapshot.
2. Monthly business performance trend.
3. Customer-state performance overview.

Metric definitions
------------------
- Orders placed: count of all rows in stg.orders.
- Delivered orders: orders with order_status = 'delivered'.
- Delivered item GMV: SUM(order_items.price) for delivered orders.
  Freight is excluded.
- Delivered AOV: delivered item GMV divided by delivered orders that have
  at least one item record. Numerator and denominator use the same population.
- Repeat customer: customer_unique_id with more than one observed order
  in this dataset.
- Delivery time: actual delivery timestamp minus purchase timestamp.
- Late delivery: actual delivery timestamp is later than the estimated
  delivery timestamp.
- Active seller: seller with at least one item in a delivered order.

Important cautions
------------------
- GMV is not profit or net marketplace revenue.
- Payment value is not treated as company revenue.
- Customer repeat behaviour is limited to the observation period.
- State-level measures are descriptive, not causal.
- Delivery metrics exclude delivered-status orders without an actual
  delivery timestamp.
- Seller count is based on sellers with delivered-order activity.
- Separate CTEs aggregate data to the required grain before joining.
  This avoids inflating totals through one-to-many joins.
- This script does not modify source or staging data.

Run each SELECT separately in pgAdmin to inspect every result grid.
*/


/* QUERY 1: Overall executive KPI snapshot.
   Grain: one row for the full dataset.
*/
WITH item_totals AS (
    SELECT
        order_id,
        SUM(price) AS item_gmv,
        SUM(freight_value) AS freight_value,
        COUNT(*) AS item_lines
    FROM stg.order_items
    GROUP BY order_id
),
order_kpis AS (
    SELECT
        COUNT(*) AS orders_placed,
        COUNT(*) FILTER (
            WHERE o.order_status = 'delivered'
        ) AS delivered_orders,
        COUNT(*) FILTER (
            WHERE o.order_status = 'canceled'
        ) AS canceled_orders,
        COUNT(*) FILTER (
            WHERE o.order_status = 'unavailable'
        ) AS unavailable_orders,
        COUNT(*) FILTER (
            WHERE o.order_status = 'delivered'
              AND i.order_id IS NOT NULL
        ) AS delivered_orders_with_items,
        COALESCE(
            SUM(i.item_gmv) FILTER (
                WHERE o.order_status = 'delivered'
            ), 0
        ) AS delivered_item_gmv,
        COALESCE(
            SUM(i.freight_value) FILTER (
                WHERE o.order_status = 'delivered'
            ), 0
        ) AS delivered_freight_value
    FROM stg.orders AS o
    LEFT JOIN item_totals AS i
        ON o.order_id = i.order_id
),
customer_kpis AS (
    SELECT
        COUNT(*) AS unique_customers,
        COUNT(*) FILTER (
            WHERE order_count > 1
        ) AS repeat_customers
    FROM (
        SELECT
            c.customer_unique_id,
            COUNT(DISTINCT o.order_id) AS order_count
        FROM stg.orders AS o
        INNER JOIN stg.customers AS c
            ON o.customer_id = c.customer_id
        WHERE c.customer_unique_id IS NOT NULL
        GROUP BY c.customer_unique_id
    ) AS customer_order_counts
),
seller_kpis AS (
    SELECT
        COUNT(DISTINCT oi.seller_id) AS active_sellers
    FROM stg.order_items AS oi
    INNER JOIN stg.orders AS o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
),
delivery_kpis AS (
    SELECT
        COUNT(*) AS delivered_orders_with_actual_timestamp,
        ROUND(
            AVG(
                EXTRACT(EPOCH FROM (
                    o.order_delivered_customer_date
                    - o.order_purchase_timestamp
                )) / 86400.0
            )::numeric,
            2
        ) AS average_delivery_days,
        ROUND(
            100.0 * COUNT(*) FILTER (
                WHERE o.order_delivered_customer_date
                      <= o.order_estimated_delivery_date
            ) / NULLIF(COUNT(*), 0),
            2
        ) AS on_time_delivery_rate_pct
    FROM stg.orders AS o
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_purchase_timestamp IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
)
SELECT
    ok.orders_placed,
    ok.delivered_orders,
    ok.canceled_orders,
    ok.unavailable_orders,
    ROUND(
        100.0 * ok.delivered_orders / NULLIF(ok.orders_placed, 0),
        2
    ) AS delivered_order_share_pct,
    ROUND(ok.delivered_item_gmv, 2) AS delivered_item_gmv,
    ROUND(ok.delivered_freight_value, 2) AS delivered_freight_value,
    ROUND(
        ok.delivered_item_gmv
        / NULLIF(ok.delivered_orders_with_items, 0),
        2
    ) AS delivered_aov_item_gmv,
    ck.unique_customers,
    ck.repeat_customers,
    ROUND(
        100.0 * ck.repeat_customers / NULLIF(ck.unique_customers, 0),
        2
    ) AS repeat_customer_rate_pct,
    sk.active_sellers,
    dk.delivered_orders_with_actual_timestamp,
    dk.average_delivery_days,
    dk.on_time_delivery_rate_pct
FROM order_kpis AS ok
CROSS JOIN customer_kpis AS ck
CROSS JOIN seller_kpis AS sk
CROSS JOIN delivery_kpis AS dk;


/* QUERY 2: Monthly business performance trend.
   Grain: one row per purchase month.
   Order-level item totals are calculated before joining to orders.
*/
WITH item_totals AS (
    SELECT
        order_id,
        SUM(price) AS item_gmv,
        SUM(freight_value) AS freight_value
    FROM stg.order_items
    GROUP BY order_id
),
monthly_orders AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp)::date
            AS purchase_month,
        COUNT(*) AS orders_placed,
        COUNT(*) FILTER (
            WHERE o.order_status = 'delivered'
        ) AS delivered_orders,
        COALESCE(
            SUM(i.item_gmv) FILTER (
                WHERE o.order_status = 'delivered'
            ), 0
        ) AS delivered_item_gmv,
        COALESCE(
            SUM(i.freight_value) FILTER (
                WHERE o.order_status = 'delivered'
            ), 0
        ) AS delivered_freight_value,
        COUNT(*) FILTER (
            WHERE o.order_status = 'delivered'
              AND i.order_id IS NOT NULL
        ) AS delivered_orders_with_items
    FROM stg.orders AS o
    LEFT JOIN item_totals AS i
        ON o.order_id = i.order_id
    WHERE o.order_purchase_timestamp IS NOT NULL
    GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
),
monthly_customers AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp)::date
            AS purchase_month,
        COUNT(DISTINCT c.customer_unique_id) AS purchasing_customers
    FROM stg.orders AS o
    INNER JOIN stg.customers AS c
        ON o.customer_id = c.customer_id
    WHERE o.order_purchase_timestamp IS NOT NULL
      AND c.customer_unique_id IS NOT NULL
    GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
)
SELECT
    mo.purchase_month,
    mo.orders_placed,
    mo.delivered_orders,
    ROUND(mo.delivered_item_gmv, 2) AS delivered_item_gmv,
    ROUND(mo.delivered_freight_value, 2) AS delivered_freight_value,
    ROUND(
        mo.delivered_item_gmv
        / NULLIF(mo.delivered_orders_with_items, 0),
        2
    ) AS delivered_aov_item_gmv,
    mc.purchasing_customers
FROM monthly_orders AS mo
LEFT JOIN monthly_customers AS mc
    ON mo.purchase_month = mc.purchase_month
ORDER BY mo.purchase_month;


/* QUERY 3: Customer-state performance overview.
   Grain: one row per customer state.
   Order/item sales and delivery performance are aggregated separately
   before joining to avoid multiplying item rows.
*/
WITH customer_state_orders AS (
    SELECT
        c.customer_state,
        o.order_id,
        o.order_status,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
    FROM stg.orders AS o
    INNER JOIN stg.customers AS c
        ON o.customer_id = c.customer_id
),
state_order_metrics AS (
    SELECT
        customer_state,
        COUNT(*) AS orders_placed,
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
        ) AS delivered_orders,
        COUNT(*) FILTER (
            WHERE order_status = 'canceled'
        ) AS canceled_orders,
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND order_delivered_customer_date IS NOT NULL
              AND order_estimated_delivery_date IS NOT NULL
        ) AS delivered_orders_with_delivery_dates,
        ROUND(
            100.0 * COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND order_delivered_customer_date IS NOT NULL
                  AND order_estimated_delivery_date IS NOT NULL
                  AND order_delivered_customer_date
                      <= order_estimated_delivery_date
            )
            / NULLIF(
                COUNT(*) FILTER (
                    WHERE order_status = 'delivered'
                      AND order_delivered_customer_date IS NOT NULL
                      AND order_estimated_delivery_date IS NOT NULL
                ),
                0
            ),
            2
        ) AS on_time_delivery_rate_pct
    FROM customer_state_orders
    GROUP BY customer_state
),
state_sales AS (
    SELECT
        c.customer_state,
        COUNT(*) AS delivered_item_lines,
        SUM(oi.price) AS delivered_item_gmv
    FROM stg.order_items AS oi
    INNER JOIN stg.orders AS o
        ON oi.order_id = o.order_id
    INNER JOIN stg.customers AS c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_state
)
SELECT
    om.customer_state,
    om.orders_placed,
    om.delivered_orders,
    om.canceled_orders,
    ROUND(
        100.0 * om.delivered_orders / NULLIF(om.orders_placed, 0),
        2
    ) AS delivered_order_share_pct,
    COALESCE(ss.delivered_item_lines, 0) AS delivered_item_lines,
    ROUND(COALESCE(ss.delivered_item_gmv, 0), 2)
        AS delivered_item_gmv,
    om.delivered_orders_with_delivery_dates,
    om.on_time_delivery_rate_pct
FROM state_order_metrics AS om
LEFT JOIN state_sales AS ss
    ON om.customer_state = ss.customer_state
ORDER BY delivered_item_gmv DESC;
