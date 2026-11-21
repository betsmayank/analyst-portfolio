/*
Project 01: Olist Brazilian E-commerce Analytics
Analysis 2: Data quality and exception investigations

Database: olist_analytics
Schema: stg

Purpose
-------
This script consolidates the additional data-quality investigations performed
during the project. It focuses on:

1. Order coverage across item and payment records.
2. Missing-record coverage by order status.
3. Direction and size of payment reconciliation differences.
4. The largest individual reconciliation discrepancies.
5. Order-status coverage in the final months of the dataset.

Run each query separately when you want to inspect its result grid.

Important notes
---------------
- The order-level coverage queries start from stg.orders so every order is
  represented in the coverage classification.
- Item and payment order IDs are reduced to distinct order IDs before joining.
  This prevents multiple item/payment rows from multiplying order counts.
- Reconciliation comparisons include only orders with both item and payment
  records.
- A difference greater than R$0.01 is an investigation flag, not proof of
  a financial error.
- The signed reconciliation difference is:
      item GMV + freight - payment value
  Negative values mean payment value is higher.
  Positive values mean item GMV + freight is higher.
- The final-period query reports order counts by status. It does not explain
  why activity is low in the final months.
*/


/* QUERY 1
   Overall order record coverage.

   Question:
   How many orders have item records, payment records, both, or neither?

   Expected output:
   One summary row with mutually exclusive coverage counts.
*/

WITH item_orders AS (
    SELECT DISTINCT
        order_id
    FROM stg.order_items
),

payment_orders AS (
    SELECT DISTINCT
        order_id
    FROM stg.order_payments
)

SELECT
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE i.order_id IS NULL
          AND p.order_id IS NULL
    ) AS missing_both,

    COUNT(*) FILTER (
        WHERE i.order_id IS NULL
          AND p.order_id IS NOT NULL
    ) AS missing_items_only,

    COUNT(*) FILTER (
        WHERE i.order_id IS NOT NULL
          AND p.order_id IS NULL
    ) AS missing_payments_only,

    COUNT(*) FILTER (
        WHERE i.order_id IS NOT NULL
          AND p.order_id IS NOT NULL
    ) AS has_both

FROM stg.orders AS o

LEFT JOIN item_orders AS i
    ON o.order_id = i.order_id

LEFT JOIN payment_orders AS p
    ON o.order_id = p.order_id;


/* QUERY 2
   Record coverage by order status.

   Question:
   Which order statuses contain orders with missing item or payment records?

   Expected output:
   One row per order-status and record-coverage combination.
*/

WITH item_orders AS (
    SELECT DISTINCT
        order_id
    FROM stg.order_items
),

payment_orders AS (
    SELECT DISTINCT
        order_id
    FROM stg.order_payments
),

order_coverage AS (
    SELECT
        o.order_id,
        o.order_status,

        CASE
            WHEN i.order_id IS NULL
             AND p.order_id IS NULL
                THEN 'Missing both'

            WHEN i.order_id IS NULL
                THEN 'Missing items'

            WHEN p.order_id IS NULL
                THEN 'Missing payments'

            ELSE 'Both available'
        END AS record_coverage

    FROM stg.orders AS o

    LEFT JOIN item_orders AS i
        ON o.order_id = i.order_id

    LEFT JOIN payment_orders AS p
        ON o.order_id = p.order_id
)

SELECT
    order_status,
    record_coverage,
    COUNT(*) AS order_count

FROM order_coverage

GROUP BY
    order_status,
    record_coverage

ORDER BY
    order_status,
    record_coverage;


/* QUERY 3
   Reconciliation differences by direction.

   Question:
   Among orders with both item and payment records, how many have:
   - payment greater than item GMV + freight;
   - item GMV + freight greater than payment;
   - values within the R$0.01 tolerance?

   Also reports average and maximum absolute difference by category.

   Expected output:
   Up to three reconciliation-status rows.
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

reconciliation AS (
    SELECT
        i.order_id,

        i.item_gmv
        + i.freight_value
        - p.payment_value AS difference

    FROM item_totals AS i

    INNER JOIN payment_totals AS p
        ON i.order_id = p.order_id
),

classified AS (
    SELECT
        order_id,
        difference,

        CASE
            WHEN difference < -0.01
                THEN 'Payment exceeds item + freight'

            WHEN difference > 0.01
                THEN 'Item + freight exceeds payment'

            ELSE 'Reconciled'
        END AS reconciliation_status

    FROM reconciliation
)

SELECT
    reconciliation_status,

    COUNT(*) AS order_count,

    ROUND(
        AVG(ABS(difference))::numeric,
        2
    ) AS average_absolute_difference,

    ROUND(
        MAX(ABS(difference))::numeric,
        2
    ) AS maximum_absolute_difference

FROM classified

GROUP BY
    reconciliation_status

ORDER BY
    order_count DESC;


/* QUERY 4
   Largest individual reconciliation discrepancies.

   Question:
   Which 25 orders have the largest absolute differences between
   item GMV + freight and recorded payment value?

   Interpretation of signed difference:
   - Negative: payment value is higher.
   - Positive: item GMV + freight is higher.

   Expected output:
   Up to 25 individual orders, ranked by discrepancy magnitude.
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
)

SELECT
    o.order_id,
    o.order_status,
    i.item_gmv,
    i.freight_value,
    p.payment_value,

    ROUND(
        (
            i.item_gmv
            + i.freight_value
            - p.payment_value
        )::numeric,
        2
    ) AS difference

FROM stg.orders AS o

INNER JOIN item_totals AS i
    ON o.order_id = i.order_id

INNER JOIN payment_totals AS p
    ON o.order_id = p.order_id

WHERE ABS(
    i.item_gmv
    + i.freight_value
    - p.payment_value
) > 0.01

ORDER BY
    ABS(
        i.item_gmv
        + i.freight_value
        - p.payment_value
    ) DESC

LIMIT 25;


/* QUERY 5
   Final-period order-status coverage.

   Question:
   Does the unusually low order activity in September and October 2018
   reflect low total order volume, or are orders present in statuses that
   were excluded from the monthly sales query?

   This query reads directly from stg.orders. It does not require item
   records and does not exclude any order status.

   Expected output:
   One row per month and order status from August 2018 onward.
*/

SELECT
    DATE_TRUNC(
        'month',
        order_purchase_timestamp
    )::date AS purchase_month,

    order_status,

    COUNT(*) AS order_count

FROM stg.orders

WHERE order_purchase_timestamp >= DATE '2018-08-01'

GROUP BY
    1,
    2

ORDER BY
    1,
    2;
