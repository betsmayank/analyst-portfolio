# Project 1 Requirements: E-commerce Business Performance & Customer Experience

## Business case

An online marketplace operations team wants to understand how product sales, customer repeat purchasing, delivery performance and customer reviews relate. The analyst must identify where management should investigate operational problems and which product or seller segments deserve attention.

## Stakeholders

- Head of Marketplace Operations: delivery performance and service quality.
- Commercial Manager: product GMV, order mix and category performance.
- Customer Experience Manager: reviews and customer experience.

## Decisions supported

1. Which product categories and seller regions contribute the largest product GMV?
2. How do delivered orders and product GMV change over time?
3. What share of customers place more than one delivered order?
4. Where are late deliveries concentrated?
5. How do delivery times relate to review scores?
6. Which operational issue should be investigated first?

## In-scope data

Olist public tables: customers, orders, order items, order payments, order reviews, products, sellers and product category name translation. The large geolocation file is excluded from the first version to keep the project focused and manageable.

## Definitions and constraints

- Product GMV is the sum of item `price` for delivered orders. Freight is reported separately.
- GMV is not marketplace net revenue, seller earnings, profit or contribution margin.
- Delivered order analysis excludes cancelled, unavailable and other non-delivered statuses unless a specific status analysis says otherwise.
- Delivery-duration metrics require valid purchase and delivery timestamps.
- Late delivery requires both actual customer delivery and estimated delivery timestamps.
- Repeat purchasing is measured with `customer_unique_id`, not `customer_id`, because the source assigns a different customer ID per order in some cases.
- Reviews are ordinal scores from 1 to 5. Correlation does not prove delivery delays caused a lower score.
- The dataset represents an anonymised Brazilian marketplace sample from 2016–2018. It is not evidence of current performance in India or Europe.

## Functional requirements

- Load source CSVs into a PostgreSQL database using documented table names.
- Profile row counts, nulls, duplicate keys and relationships.
- Create SQL transformations and reusable analysis queries.
- Build a Power BI model with clearly defined measures.
- Build report pages for executive overview, sales/category performance, delivery performance and customer experience.
- Reconcile key dashboard KPIs against SQL results.
- Publish a README, data dictionary, SQL files, dashboard file or screenshots, insight memo and limitations.

## Acceptance criteria

- Every dashboard KPI has a definition and a reproducible calculation.
- Delivered-order and all-order denominators are never mixed without explanation.
- Freight is not silently included in product GMV.
- No profit claim is made because cost and margin data are not provided.
- All findings use actual verified outputs, not assumed results.
