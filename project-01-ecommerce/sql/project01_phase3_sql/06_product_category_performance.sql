/*
Project 01: Olist Brazilian E-commerce Analytics
Phase 3, Analysis 5: Product and category performance
Database: olist_analytics
Schema: stg

Purpose
-------
Analyse delivered product sales by category, compare category volume and value,
examine average item prices and freight burden, and measure category GMV
concentration.

Definitions
-----------
- Delivered item GMV: SUM(order_items.price) for delivered orders.
- Delivered item line: one row in stg.order_items for a delivered order.
- Average item price: average price per delivered item line, not per order.
- Freight-to-item-value ratio: SUM(freight_value) / SUM(price).
- Category label: English translation where available, otherwise original
  category name, otherwise 'unknown_or_uncategorized'.

Scope and cautions
------------------
- Only delivered orders are included.
- Freight is reported separately and is not included in item GMV.
- One order can contain multiple item lines and categories.
- Average item price is line-weighted, not an average order value.
- Freight-to-item-value is descriptive, not a profit or margin measure.
- Category results depend on product-category mappings in staging tables.
- This script does not modify source or staging data.
- Run each SELECT separately in pgAdmin to inspect every result grid.
*/


/* QUERY 1: Category performance overview.
   Grain: one row per category.
*/
WITH category_item_sales AS (
    SELECT
        COALESCE(
            t.product_category_name_english,
            p.product_category_name,
            'unknown_or_uncategorized'
        ) AS product_category,
        oi.order_id,
        oi.price,
        oi.freight_value
    FROM stg.order_items AS oi
    INNER JOIN stg.orders AS o
        ON oi.order_id = o.order_id
    LEFT JOIN stg.products AS p
        ON oi.product_id = p.product_id
    LEFT JOIN stg.product_category_name_translation AS t
        ON p.product_category_name = t.product_category_name
    WHERE o.order_status = 'delivered'
)
SELECT
    product_category,
    COUNT(*) AS delivered_item_lines,
    COUNT(DISTINCT order_id) AS delivered_orders,
    ROUND(SUM(price), 2) AS delivered_item_gmv,
    ROUND(SUM(freight_value), 2) AS delivered_freight_value,
    ROUND(AVG(price), 2) AS average_item_price,
    ROUND(100.0 * SUM(freight_value) / NULLIF(SUM(price), 0), 2)
        AS freight_to_item_value_pct
FROM category_item_sales
GROUP BY product_category
ORDER BY delivered_item_gmv DESC;


/* QUERY 2: Top 20 categories by delivered item volume.
   Grain: one row per category, limited to the 20 categories with the most
   delivered item lines. Volume ranking is separate from GMV ranking.
*/
WITH category_volume AS (
    SELECT
        COALESCE(
            t.product_category_name_english,
            p.product_category_name,
            'unknown_or_uncategorized'
        ) AS product_category,
        COUNT(*) AS delivered_item_lines,
        COUNT(DISTINCT oi.order_id) AS delivered_orders,
        SUM(oi.price) AS delivered_item_gmv
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
    ROUND(delivered_item_gmv, 2) AS delivered_item_gmv,
    ROUND(100.0 * delivered_item_lines
        / NULLIF(SUM(delivered_item_lines) OVER (), 0), 2)
        AS share_of_delivered_item_lines_pct
FROM category_volume
ORDER BY delivered_item_lines DESC
LIMIT 20;


/* QUERY 3: Category GMV concentration.
   Grain: one row per category. Shows individual and cumulative category shares.
*/
WITH category_sales AS (
    SELECT
        COALESCE(
            t.product_category_name_english,
            p.product_category_name,
            'unknown_or_uncategorized'
        ) AS product_category,
        SUM(oi.price) AS delivered_item_gmv
    FROM stg.order_items AS oi
    INNER JOIN stg.orders AS o
        ON oi.order_id = o.order_id
    LEFT JOIN stg.products AS p
        ON oi.product_id = p.product_id
    LEFT JOIN stg.product_category_name_translation AS t
        ON p.product_category_name = t.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY 1
),
category_shares AS (
    SELECT
        product_category,
        delivered_item_gmv,
        100.0 * delivered_item_gmv
            / NULLIF(SUM(delivered_item_gmv) OVER (), 0)
            AS category_gmv_share_pct
    FROM category_sales
)
SELECT
    product_category,
    ROUND(delivered_item_gmv, 2) AS delivered_item_gmv,
    ROUND(category_gmv_share_pct, 2) AS category_gmv_share_pct,
    ROUND(SUM(category_gmv_share_pct) OVER (
        ORDER BY delivered_item_gmv DESC, product_category
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )::numeric, 2) AS cumulative_gmv_share_pct
FROM category_shares
ORDER BY delivered_item_gmv DESC, product_category;


/* QUERY 4: Category freight burden.
   Grain: one row per category. Freight is a cost-burden indicator, not margin.
*/
WITH category_freight AS (
    SELECT
        COALESCE(
            t.product_category_name_english,
            p.product_category_name,
            'unknown_or_uncategorized'
        ) AS product_category,
        COUNT(*) AS delivered_item_lines,
        SUM(oi.price) AS delivered_item_gmv,
        SUM(oi.freight_value) AS delivered_freight_value
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
    ROUND(delivered_item_gmv, 2) AS delivered_item_gmv,
    ROUND(delivered_freight_value, 2) AS delivered_freight_value,
    ROUND(100.0 * delivered_freight_value
        / NULLIF(delivered_item_gmv, 0), 2) AS freight_to_item_value_pct,
    ROUND(delivered_freight_value
        / NULLIF(delivered_item_lines, 0), 2) AS average_freight_per_item_line
FROM category_freight
ORDER BY freight_to_item_value_pct DESC;


/* QUERY 5: Delivered sales with missing or unusable category mapping.
   Diagnostic counts for missing products, missing original categories,
   and categories without an English translation.
*/
SELECT
    COUNT(*) AS delivered_item_lines,
    COUNT(*) FILTER (
        WHERE p.product_id IS NULL
    ) AS item_lines_without_matching_product,
    COUNT(*) FILTER (
        WHERE p.product_id IS NOT NULL
          AND NULLIF(BTRIM(p.product_category_name), '') IS NULL
    ) AS item_lines_without_original_category,
    COUNT(*) FILTER (
        WHERE p.product_id IS NOT NULL
          AND NULLIF(BTRIM(p.product_category_name), '') IS NOT NULL
          AND t.product_category_name_english IS NULL
    ) AS item_lines_without_english_translation,
    ROUND(SUM(oi.price) FILTER (
        WHERE p.product_id IS NULL
           OR NULLIF(BTRIM(p.product_category_name), '') IS NULL
           OR t.product_category_name_english IS NULL
    ), 2) AS delivered_item_gmv_without_english_translation
FROM stg.order_items AS oi
INNER JOIN stg.orders AS o
    ON oi.order_id = o.order_id
LEFT JOIN stg.products AS p
    ON oi.product_id = p.product_id
LEFT JOIN stg.product_category_name_translation AS t
    ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered';
