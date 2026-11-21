/*
Project 01: Olist review identifier investigation
Purpose: Confirm how repeated review_id values behave in the staging dataset.
Run against database: olist_analytics
This is read-only. Do not delete records based on review_id alone.
*/

-- Summary: repeated review_id groups and whether they span distinct orders.
SELECT
    COUNT(*) AS repeated_review_id_groups,
    COALESCE(SUM(review_rows - 1), 0) AS extra_rows_in_those_groups,
    MAX(review_rows) AS maximum_rows_for_one_review_id,
    COUNT(*) FILTER (WHERE distinct_orders > 1) AS groups_spanning_multiple_orders,
    COUNT(*) FILTER (WHERE distinct_orders = 1) AS groups_for_one_order
FROM (
    SELECT
        review_id,
        COUNT(*) AS review_rows,
        COUNT(DISTINCT order_id) AS distinct_orders
    FROM stg.order_reviews
    GROUP BY review_id
    HAVING COUNT(*) > 1
) d;

-- The composite key should have no duplicate groups.
SELECT COUNT(*) AS duplicate_review_id_order_id_groups
FROM (
    SELECT review_id, order_id
    FROM stg.order_reviews
    GROUP BY review_id, order_id
    HAVING COUNT(*) > 1
) d;

-- Inspect representative repeated IDs without changing the source data.
SELECT
    review_id,
    COUNT(*) AS row_count,
    COUNT(DISTINCT order_id) AS distinct_orders,
    COUNT(DISTINCT review_score) AS distinct_scores
FROM stg.order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY row_count DESC, review_id
LIMIT 20;
