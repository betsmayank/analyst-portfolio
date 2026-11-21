/*
Project 01: Olist Brazilian E-commerce Analytics
Phase 3, Analysis 4: Seller performance

Database: olist_analytics
Schema: stg

Purpose
-------
Compare seller activity, delivered merchandise value, customer reach,
geographic concentration, and the distribution of sales across sellers.

Business questions
1. Which sellers generate the highest delivered item GMV?
2. How concentrated is delivered item GMV among the largest sellers?
3. How does seller activity and delivered item GMV vary by seller state?
4. How many orders and customers does each seller serve, and what is the
   average delivered item GMV per seller-order?

Definitions
-----------
- Seller-order: one distinct combination of seller_id and order_id.
- Delivered item GMV: sum of item price for delivered order items.
  Freight is excluded.
- Seller customer count: distinct customer_unique_id values associated with
  the seller's delivered orders.
- Seller state: seller_state from stg.sellers, not customer_state.

Scope and cautions
------------------
- GMV includes delivered order items only.
- A single order can contain items from multiple sellers. Seller-level order
  counts can therefore sum to more than the number of unique orders overall.
- Seller-order GMV is aggregated before seller-level averages are calculated.
- Sellers without delivered item GMV do not appear in the delivered-sales
  rankings.
- Seller-state comparisons are descriptive, not causal.
- This script does not modify source or staging data.

Run each SELECT separately in pgAdmin to inspect every result grid.
*/


/* QUERY 1: Seller-level delivered sales performance.

   Grain: one row per seller.
   Calculates delivered item GMV, delivered seller-orders, distinct customers,
   item lines, and average delivered item GMV per seller-order.
*/

WITH seller_order_sales AS (
    SELECT
        oi.seller_id,
        o.order_id,
        c.customer_unique_id,
        SUM(oi.price) AS seller_order_item_gmv,
        COUNT(*) AS item_lines
    FROM stg.order_items AS oi
    INNER JOIN stg.orders AS o
        ON oi.order_id = o.order_id
    LEFT JOIN stg.customers AS c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        oi.seller_id,
        o.order_id,
        c.customer_unique_id
)
SELECT
    s.seller_id,
    s.seller_state,
    COUNT(*) AS delivered_seller_orders,
    COUNT(DISTINCT sos.customer_unique_id) AS distinct_customers,
    SUM(sos.item_lines) AS delivered_item_lines,
    ROUND(SUM(sos.seller_order_item_gmv), 2) AS delivered_item_gmv,
    ROUND(AVG(sos.seller_order_item_gmv), 2)
        AS average_item_gmv_per_seller_order
FROM seller_order_sales AS sos
INNER JOIN stg.sellers AS s
    ON sos.seller_id = s.seller_id
GROUP BY s.seller_id, s.seller_state
ORDER BY delivered_item_gmv DESC;


/* QUERY 2: Delivered item GMV concentration among sellers.

   Grain: one row per seller, ordered by delivered item GMV.
   Calculates each seller's share of total delivered item GMV and cumulative
   share. This helps assess how much sales value is concentrated among the
   largest sellers.
*/

WITH seller_sales AS (
    SELECT
        oi.seller_id,
        SUM(oi.price) AS delivered_item_gmv
    FROM stg.order_items AS oi
    INNER JOIN stg.orders AS o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id
),
seller_shares AS (
    SELECT
        seller_id,
        delivered_item_gmv,
        100.0 * delivered_item_gmv
            / NULLIF(SUM(delivered_item_gmv) OVER (), 0)
            AS seller_gmv_share_pct
    FROM seller_sales
)
SELECT
    seller_id,
    ROUND(delivered_item_gmv::numeric, 2) AS delivered_item_gmv,
    ROUND(seller_gmv_share_pct::numeric, 2) AS seller_gmv_share_pct,
    ROUND(
        SUM(seller_gmv_share_pct) OVER (
            ORDER BY delivered_item_gmv DESC, seller_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )::numeric,
        2
    ) AS cumulative_gmv_share_pct
FROM seller_shares
ORDER BY delivered_item_gmv DESC, seller_id;


/* QUERY 3: Seller performance by seller state.

   Grain: one row per seller state.
   Aggregates seller count, delivered seller-orders, delivered item GMV,
   average GMV per seller, and average GMV per seller-order.
*/

WITH seller_order_sales AS (
    SELECT
        oi.seller_id,
        o.order_id,
        SUM(oi.price) AS seller_order_item_gmv
    FROM stg.order_items AS oi
    INNER JOIN stg.orders AS o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id, o.order_id
),
seller_totals AS (
    SELECT
        s.seller_id,
        s.seller_state,
        COUNT(*) AS delivered_seller_orders,
        SUM(sos.seller_order_item_gmv) AS delivered_item_gmv
    FROM seller_order_sales AS sos
    INNER JOIN stg.sellers AS s
        ON sos.seller_id = s.seller_id
    GROUP BY s.seller_id, s.seller_state
)
SELECT
    seller_state,
    COUNT(*) AS active_sellers_with_delivered_sales,
    SUM(delivered_seller_orders) AS delivered_seller_orders,
    ROUND(SUM(delivered_item_gmv), 2) AS delivered_item_gmv,
    ROUND(AVG(delivered_item_gmv), 2) AS average_gmv_per_seller,
    ROUND(
        SUM(delivered_item_gmv)
        / NULLIF(SUM(delivered_seller_orders), 0),
        2
    ) AS average_gmv_per_seller_order
FROM seller_totals
GROUP BY seller_state
ORDER BY delivered_item_gmv DESC;


/* QUERY 4: Seller monthly delivered sales trend.

   Grain: one row per seller per purchase month.
   Useful for comparing seller activity over time. Only seller-months with
   delivered item sales are returned.
*/

SELECT
    oi.seller_id,
    DATE_TRUNC('month', o.order_purchase_timestamp)::date AS purchase_month,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    COUNT(*) AS delivered_item_lines,
    ROUND(SUM(oi.price), 2) AS delivered_item_gmv
FROM stg.order_items AS oi
INNER JOIN stg.orders AS o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY
    oi.seller_id,
    DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY
    oi.seller_id,
    purchase_month;
