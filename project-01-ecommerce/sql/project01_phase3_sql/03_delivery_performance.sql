/*
Project 01: Olist Brazilian E-commerce Analytics
Phase 3, Analysis 2: Delivery performance

Database: olist_analytics
Schema: stg

Purpose
-------
Evaluate delivery speed, delivery reliability, and differences across
purchase months and customer states.

Business questions
1. How long did delivered orders take to reach customers?
2. What share arrived by the estimated delivery date?
3. Did delivery performance vary by purchase month?
4. Which customer states had relatively higher late-delivery rates?

Definitions
-----------
- Delivery time: calendar days from purchase timestamp to customer delivery.
- Estimated delay: actual customer delivery date minus estimated delivery date.
  Positive = late; zero = delivered on the estimated date; negative = early.
- On-time rate: delivered orders with actual delivery on or before the estimate,
  divided by eligible delivered orders with both timestamps.
- Late rate: delivered orders with actual delivery after the estimate,
  divided by the same eligible population.

Scope and cautions
------------------
- Only orders with order_status = 'delivered' and both actual and estimated
  delivery timestamps are included in delivery-performance calculations.
- Orders missing either timestamp are excluded from these calculations.
- State results describe the customer's state, not the seller's state.
- State comparisons are descriptive, not causal. Small groups can produce
  unstable rates, so the state query includes an order-count threshold.
- Delivery time is measured in calendar days, not business days.
- This script does not change any source or staging data.

Run each SELECT separately in pgAdmin to inspect every result grid.
*/


/* QUERY 1: Overall delivery performance.

   Grain: one summary row for the eligible delivered-order population.

   Includes average and median delivery time, early/on-date/late counts,
   on-time and late rates, and the severity of late deliveries.
*/

WITH delivered_orders AS (
    SELECT
        order_id,
        order_purchase_timestamp,
        order_delivered_customer_date,
        order_estimated_delivery_date,
        EXTRACT(EPOCH FROM (
            order_delivered_customer_date - order_purchase_timestamp
        )) / 86400.0 AS delivery_days,
        (
            order_delivered_customer_date::date
            - order_estimated_delivery_date::date
        ) AS delay_days
    FROM stg.orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
)
SELECT
    COUNT(*) AS eligible_delivered_orders,
    ROUND(AVG(delivery_days)::numeric, 2) AS average_delivery_days,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY delivery_days)::numeric, 2)
        AS median_delivery_days,
    COUNT(*) FILTER (WHERE delay_days < 0) AS delivered_early,
    COUNT(*) FILTER (WHERE delay_days = 0) AS delivered_on_estimated_date,
    COUNT(*) FILTER (WHERE delay_days > 0) AS delivered_late,
    ROUND(100.0 * COUNT(*) FILTER (WHERE delay_days <= 0)
        / NULLIF(COUNT(*), 0), 2) AS on_time_rate_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE delay_days > 0)
        / NULLIF(COUNT(*), 0), 2) AS late_rate_pct,
    ROUND(AVG(delay_days) FILTER (WHERE delay_days > 0)::numeric, 2)
        AS average_days_late,
    MAX(delay_days) FILTER (WHERE delay_days > 0) AS maximum_days_late
FROM delivered_orders;


/* QUERY 2: Delivery performance by purchase month.

   Grain: one row per purchase month. The denominator is eligible delivered
   orders with both actual and estimated delivery timestamps.
*/

WITH delivered_orders AS (
    SELECT
        DATE_TRUNC('month', order_purchase_timestamp)::date AS purchase_month,
        EXTRACT(EPOCH FROM (
            order_delivered_customer_date - order_purchase_timestamp
        )) / 86400.0 AS delivery_days,
        (
            order_delivered_customer_date::date
            - order_estimated_delivery_date::date
        ) AS delay_days
    FROM stg.orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
)
SELECT
    purchase_month,
    COUNT(*) AS eligible_delivered_orders,
    ROUND(AVG(delivery_days)::numeric, 2) AS average_delivery_days,
    ROUND(100.0 * COUNT(*) FILTER (WHERE delay_days <= 0)
        / NULLIF(COUNT(*), 0), 2) AS on_time_rate_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE delay_days > 0)
        / NULLIF(COUNT(*), 0), 2) AS late_rate_pct,
    ROUND(AVG(delay_days) FILTER (WHERE delay_days > 0)::numeric, 2)
        AS average_days_late
FROM delivered_orders
GROUP BY purchase_month
ORDER BY purchase_month;


/* QUERY 3: Delivery performance by customer state.

   Grain: one row per customer state. The 100-order threshold avoids
   highlighting states with very small eligible populations.
*/

WITH delivered_orders AS (
    SELECT
        o.order_id,
        c.customer_state,
        EXTRACT(EPOCH FROM (
            o.order_delivered_customer_date - o.order_purchase_timestamp
        )) / 86400.0 AS delivery_days,
        (
            o.order_delivered_customer_date::date
            - o.order_estimated_delivery_date::date
        ) AS delay_days
    FROM stg.orders AS o
    INNER JOIN stg.customers AS c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
)
SELECT
    customer_state,
    COUNT(*) AS eligible_delivered_orders,
    ROUND(AVG(delivery_days)::numeric, 2) AS average_delivery_days,
    ROUND(100.0 * COUNT(*) FILTER (WHERE delay_days > 0)
        / NULLIF(COUNT(*), 0), 2) AS late_rate_pct,
    ROUND(AVG(delay_days) FILTER (WHERE delay_days > 0)::numeric, 2)
        AS average_days_late
FROM delivered_orders
GROUP BY customer_state
HAVING COUNT(*) >= 100
ORDER BY late_rate_pct DESC, eligible_delivered_orders DESC;


/* QUERY 4: Delivery delay severity.

   Grain: one row per delivery-outcome band. This separates slightly late
   orders from orders that missed the estimated date by longer periods.
*/

WITH delivered_orders AS (
    SELECT
        order_delivered_customer_date::date
        - order_estimated_delivery_date::date AS delay_days
    FROM stg.orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
),
classified_orders AS (
    SELECT
        CASE
            WHEN delay_days < 0 THEN 'Early'
            WHEN delay_days = 0 THEN 'On estimated date'
            WHEN delay_days BETWEEN 1 AND 3 THEN '1-3 days late'
            WHEN delay_days BETWEEN 4 AND 7 THEN '4-7 days late'
            WHEN delay_days BETWEEN 8 AND 14 THEN '8-14 days late'
            ELSE '15+ days late'
        END AS delivery_outcome,
        CASE
            WHEN delay_days < 0 THEN 1
            WHEN delay_days = 0 THEN 2
            WHEN delay_days BETWEEN 1 AND 3 THEN 3
            WHEN delay_days BETWEEN 4 AND 7 THEN 4
            WHEN delay_days BETWEEN 8 AND 14 THEN 5
            ELSE 6
        END AS sort_order
    FROM delivered_orders
)
SELECT
    delivery_outcome,
    COUNT(*) AS order_count,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2)
        AS share_of_eligible_delivered_orders_pct
FROM classified_orders
GROUP BY delivery_outcome, sort_order
ORDER BY sort_order;


/* QUERY 5: Delivery timestamp and chronology checks.

   Diagnostic counts for delivered-status orders with missing dates or
   impossible timestamp sequences. Investigate exceptions before calling
   them data errors.
*/

SELECT
    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
    ) AS delivered_status_orders,
    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND order_delivered_customer_date IS NULL
    ) AS delivered_without_actual_delivery_timestamp,
    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND order_estimated_delivery_date IS NULL
    ) AS delivered_without_estimated_delivery_timestamp,
    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND order_delivered_customer_date IS NOT NULL
          AND order_purchase_timestamp IS NOT NULL
          AND order_delivered_customer_date < order_purchase_timestamp
    ) AS delivered_before_purchase,
    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND order_delivered_customer_date IS NOT NULL
          AND order_estimated_delivery_date IS NOT NULL
          AND order_estimated_delivery_date < order_purchase_timestamp
    ) AS estimated_date_before_purchase
FROM stg.orders;
