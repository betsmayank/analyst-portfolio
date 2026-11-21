# Project 01 - Phase 3, Analysis 1: Sales Performance

Run `01_sales_performance.sql` in the `olist_analytics` PostgreSQL database after the `stg` schema has been built and validated.

## Execution

In pgAdmin Query Tool, select and execute each `SELECT` statement separately with F5 so each result grid can be inspected and saved.

## Metric cautions

- Item GMV is the sum of `stg.order_items.price`; freight is reported separately.
- Delivered sales use `stg.orders.order_status = 'delivered'`.
- Missing delivery timestamps do not alter delivered sales classification; they are an exception for delivery-time analysis only.
- Payment value is not synonymous with marketplace revenue. The data does not contain marketplace commission, operating expenses, or profit.
- Query 4 is a reconciliation diagnostic. Differences should be investigated, not automatically treated as data errors.
- Item and payment tables are aggregated separately to order level before joining to prevent join fanout.
