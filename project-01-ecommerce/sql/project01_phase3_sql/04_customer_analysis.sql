/*
Project 01: Olist Brazilian E-commerce Analytics
Phase 3, Analysis 3: Customer behaviour and repeat purchasing
Database: olist_analytics
Schema: stg

Business questions
1. How many unique customers placed one order versus multiple orders?
2. How is observed order frequency distributed across customers?
3. How has the share of first-time and repeat-customer orders changed monthly?
4. How much delivered item GMV is associated with one-time and repeat customers?
5. Do observed repeat-purchase rates vary by customer state?

Definitions and cautions
- Customer identity uses customer_unique_id, not customer_id.
- A repeat customer has more than one observed order in this dataset.
- First-time means the earliest order observed within this dataset.
- The dataset covers a limited historical period. One observed order does not
  prove that a customer never purchased before or after this period.
- Delivered item GMV is the sum of item price for delivered orders; freight
  is excluded. GMV is not profit or net company revenue.
- State results describe customer state and are descriptive, not causal.
- No customer-level personally identifying fields are output.
- This script does not modify source or staging data.

Run each SELECT separately in pgAdmin to inspect every result grid.
*/


/* QUERY 1: One-time versus repeat customers.
   Grain: one summary row. Repeat rate uses unique customers as denominator.
*/
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM stg.orders AS o
    INNER JOIN stg.customers AS c
        ON o.customer_id = c.customer_id
    WHERE c.customer_unique_id IS NOT NULL
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*) AS unique_customers,
    COUNT(*) FILTER (WHERE order_count = 1) AS one_time_customers,
    COUNT(*) FILTER (WHERE order_count > 1) AS repeat_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE order_count > 1)
        / NULLIF(COUNT(*), 0), 2) AS repeat_customer_rate_pct,
    SUM(order_count) AS orders_from_identified_customers
FROM customer_orders;


/* QUERY 2: Distribution of observed order frequency.
   Grain: one row per frequency band.
*/
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM stg.orders AS o
    INNER JOIN stg.customers AS c
        ON o.customer_id = c.customer_id
    WHERE c.customer_unique_id IS NOT NULL
    GROUP BY c.customer_unique_id
),
frequency_bands AS (
    SELECT
        CASE
            WHEN order_count = 1 THEN '1 order'
            WHEN order_count = 2 THEN '2 orders'
            WHEN order_count = 3 THEN '3 orders'
            WHEN order_count = 4 THEN '4 orders'
            ELSE '5+ orders'
        END AS order_frequency,
        CASE
            WHEN order_count = 1 THEN 1
            WHEN order_count = 2 THEN 2
            WHEN order_count = 3 THEN 3
            WHEN order_count = 4 THEN 4
            ELSE 5
        END AS sort_order
    FROM customer_orders
)
SELECT
    order_frequency,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2)
        AS share_of_customers_pct
FROM frequency_bands
GROUP BY order_frequency, sort_order
ORDER BY sort_order;


/* QUERY 3: Monthly first-time versus repeat-customer orders.
   Each customer's earliest observed order is first-time; subsequent observed
   orders are repeat-customer orders. Ties are deterministically ordered by ID.
*/
WITH customer_order_sequence AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_purchase_timestamp, o.order_id
        ) AS customer_order_number
    FROM stg.orders AS o
    INNER JOIN stg.customers AS c
        ON o.customer_id = c.customer_id
    WHERE c.customer_unique_id IS NOT NULL
      AND o.order_purchase_timestamp IS NOT NULL
)
SELECT
    DATE_TRUNC('month', order_purchase_timestamp)::date AS purchase_month,
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE customer_order_number = 1)
        AS first_time_customer_orders,
    COUNT(*) FILTER (WHERE customer_order_number > 1)
        AS repeat_customer_orders,
    ROUND(100.0 * COUNT(*) FILTER (WHERE customer_order_number > 1)
        / NULLIF(COUNT(*), 0), 2) AS repeat_customer_order_share_pct
FROM customer_order_sequence
GROUP BY DATE_TRUNC('month', order_purchase_timestamp)
ORDER BY purchase_month;


/* QUERY 4: Delivered item GMV by observed customer purchase frequency.
   Frequency uses all observed order statuses. GMV includes delivered orders
   only and excludes freight. Customer is counted once in each group.
*/
WITH customer_order_counts AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS observed_order_count
    FROM stg.orders AS o
    INNER JOIN stg.customers AS c
        ON o.customer_id = c.customer_id
    WHERE c.customer_unique_id IS NOT NULL
    GROUP BY c.customer_unique_id
),
customer_gmv AS (
    SELECT
        c.customer_unique_id,
        SUM(oi.price) FILTER (WHERE o.order_status = 'delivered')
            AS delivered_item_gmv
    FROM stg.orders AS o
    INNER JOIN stg.customers AS c
        ON o.customer_id = c.customer_id
    LEFT JOIN stg.order_items AS oi
        ON o.order_id = oi.order_id
    WHERE c.customer_unique_id IS NOT NULL
    GROUP BY c.customer_unique_id
)
SELECT
    CASE
        WHEN coc.observed_order_count = 1 THEN 'One-time customer'
        ELSE 'Repeat customer'
    END AS customer_type,
    COUNT(*) AS customer_count,
    COUNT(*) FILTER (WHERE cg.delivered_item_gmv IS NOT NULL)
        AS customers_with_delivered_item_gmv,
    ROUND(SUM(cg.delivered_item_gmv), 2) AS delivered_item_gmv,
    ROUND(AVG(cg.delivered_item_gmv), 2)
        AS average_delivered_item_gmv_per_customer
FROM customer_order_counts AS coc
LEFT JOIN customer_gmv AS cg
    ON coc.customer_unique_id = cg.customer_unique_id
GROUP BY customer_type
ORDER BY customer_type;


/* QUERY 5: Repeat-purchase rate by customer state.
   A repeat customer has more than one observed order. The 100-customer
   threshold reduces instability in very small groups.
*/
WITH customer_state_orders AS (
    SELECT
        c.customer_unique_id,
        c.customer_state,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM stg.orders AS o
    INNER JOIN stg.customers AS c
        ON o.customer_id = c.customer_id
    WHERE c.customer_unique_id IS NOT NULL
      AND c.customer_state IS NOT NULL
    GROUP BY c.customer_unique_id, c.customer_state
)
SELECT
    customer_state,
    COUNT(*) AS unique_customers,
    COUNT(*) FILTER (WHERE order_count > 1) AS repeat_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE order_count > 1)
        / NULLIF(COUNT(*), 0), 2) AS repeat_customer_rate_pct
FROM customer_state_orders
GROUP BY customer_state
HAVING COUNT(*) >= 100
ORDER BY repeat_customer_rate_pct DESC, unique_customers DESC;
