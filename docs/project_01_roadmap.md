# Project 01 Roadmap — E-commerce Business Performance & Customer Experience

**Current status:** Seven SQL analyses complete; Power BI development is the next phase.  
**Dataset:** Olist Brazilian E-Commerce Public Dataset (2016–2018).  
**Tools:** PostgreSQL 18, pgAdmin 4, SQL, Power BI Desktop, DAX, GitHub.

## 1. Executive status

| Original phase | Scope | Status | Evidence / output |
|---|---|---|---|
| Phase 1 — Foundation | Portfolio repository, Git/GitHub, tools, project requirements and process flow | **Complete** | Public GitHub repository and starter documentation |
| Phase 2 — Data preparation | Olist source files, PostgreSQL database, raw imports, staging tables, data profiling and quality checks | **Complete** | Nine raw tables and nine typed staging tables; source and staging row counts match |
| Phase 3 — SQL business analysis | Seven analysis files covering sales/payments, data quality, delivery, customers, sellers, categories and executive KPIs | **Complete** | Seven files marked Completed in tracker; seven visual summaries and four original working documents reviewed |
| Phase 4 — Power BI and publication | Semantic model, DAX, report pages, SQL-to-Power-BI reconciliation, insight memo, README and GitHub publication | **Next / In progress** | Implementation plan prepared; model/report not yet demonstrated in supplied evidence |

**Do not repeat Phase 2 or the seven completed SQL analyses.** The completed SQL files remain the analytical source of truth. Phase 4 should consume their existing outputs and reconcile model measures to them. Add a new SQL query only if a specific model-validation gap cannot be resolved from completed files.

## 2. Completed SQL analysis register

| # | Analysis | SQL file | Status | Main outputs captured |
|---:|---|---|---|---|
| 01 | Sales performance and payment methods | `01_sales_performance.sql` | **Completed** | Monthly GMV peak R$1,003,862.14 in Nov 2017; payment-value shares: credit card 73.6%, boleto 19.2%, voucher 5.2%, debit card 1.9%, other 0.1%; delivered item GMV R$13.22M |
| 02 | Data quality and reconciliation | `02_data_quality_investigations.sql` | **Completed** | 98,665 matched; 98,362 within R$0.01; 303 exceptions; 775 missing item records; one missing payment; repeated review IDs with composite key validated |
| 03 | Delivery performance | `03_delivery_performance.sql` | **Completed** | Average delivery time 12.56 days; 93.23% calendar-date on-time; 6,534 late; state variation |
| 04 | Customer analysis | `04_customer_analysis.sql` | **Completed** | 96,096 unique; 2,997 repeat (3.12%); frequency and segment GMV; segment averages denominators clarified |
| 05 | Seller performance | `05_seller_performance.sql` | **Completed** | 2,970 active sellers; top-10 share 13.27%; seller-state contribution |
| 06 | Product category performance | `06_product_category_performance.sql` | **Completed** | 74 categories; 110,197 item lines; top-10 category share 62.43%; freight burden and missing category mapping |
| 07 | Executive KPI overview | `07_executive_kpi_overview.sql` | **Completed** | Consolidated order, GMV, AOV, customer, seller, delivery and customer-state KPIs |

The documentation package does not include or replace these seven SQL scripts. Their existing project files remain unchanged.

## 3. Confirmed dataset and preparation facts

- Nine source tables were imported into `raw`; nine typed tables were created in `stg`.
- Reference row counts: customers 99,441; geolocation 1,000,163; order items 112,650; payments 103,886; reviews 99,224; orders 99,441; category translations 71; products 32,951; sellers 3,095.
- The arithmetic sum of the nine table row counts is **1,550,922 rows**. These tables have different grains; this is not an order count or a count of unique people.
- Orders span 2016-09-04 through 2018-10-17. First and last calendar months are partial and must not be compared as full months without a caveat.
- Order statuses: delivered 96,478 (97.02%); shipped 1,107; canceled 625; unavailable 609; invoiced 314; processing 301; created 5; approved 2.
- Eight orders marked delivered lack an actual delivery timestamp. The delivery analysis uses 96,470 eligible delivered orders with required dates. Six orders in other statuses have an actual delivery timestamp.
- Payment record coverage: 98,665 orders have both item and payment records; 775 are missing item records; one is missing payment data; none are missing both.

## 4. Phase 4 — Power BI build plan

### Goal
Build a reproducible Power BI semantic model and executive-facing report using the completed PostgreSQL staging data and seven completed SQL analyses.

### Deliverables

1. `powerbi/olist_ecommerce_business_performance.pbix`.
2. A documented semantic model with table grains and verified relationships.
3. A proper date table and clearly named DAX measures.
4. Four report pages:
   - **Executive Overview:** orders, delivered orders, delivered item GMV, delivered item AOV, repeat-customer rate, active sellers, delivery time and customer-state summary.
   - **Sales & Product Performance:** monthly sales measure with explicit filter label, category ranking, category concentration and freight-to-item-value ratio.
   - **Customer & Seller Performance:** order-frequency distribution, repeat-customer metrics, seller contribution and customer-state/seller-state geography.
   - **Delivery & Data Quality:** delivery duration, 93.23% calendar-date on-time rate, 6,534 late orders, state variation, missing-record coverage and 303 reconciliation exceptions.
5. A SQL-to-Power-BI reconciliation sheet listing each key KPI, SQL value, DAX value, difference and sign-off status.
6. Report screenshots in `project-01-ecommerce/screenshots/`, a final insight memo, README updates and the PBIX.

### Model scope

Start with these staging tables: `stg.orders`, `stg.order_items`, `stg.customers`, `stg.products`, `stg.sellers`, `stg.order_payments`, `stg.order_reviews`, and `stg.product_category_name_translation`.

Keep `stg.geolocation` in PostgreSQL for the first Power BI version. State-level findings can be represented using customer and seller state fields already present in their respective tables; importing the million-row geolocation table is not necessary for the first report.

Model order, item, payment and review data at their correct grains. Do not merge item lines and payment rows into one flattened table: both are one-to-many from an order and a direct join can multiply amounts. Use separate measures over their respective tables. Verify key uniqueness/cardinality before accepting relationships. Use single-direction filtering as the default and avoid unnecessary many-to-many relationships.

## 5. KPI reconciliation gates before sign-off

- Keep **96,478 delivered-status orders** separate from **96,470 eligible delivered orders with required delivery dates**.
- Use **93.23% calendar-date on-time delivery** for the delivery dashboard. Keep the alternate **91.89% timestamp-level** result separate and explicitly labelled if retained.
- Repeat-customer rate is **2,997 / 96,096 = 3.12%**. Segment delivered-GMV averages are **R$255.25 = R$760,377.86 / 2,979 repeat customers with delivered GMV** and **R$137.88 = R$12,461,120.25 / 90,379 one-time customers with delivered GMV**. The earlier apparent denominator issue is resolved; DAX must use these exact populations.
- Keep monthly GMV series distinct from delivered-only GMV. The completed sales query exposes multiple monthly item-value expressions; use the exact column and status filter for each visual. Do not force a common label if the populations differ.
- Payment-method shares are based on **payment value**, not counts of payment rows, orders or customers.
- Use customer-state and seller-state labels distinctly. They are different geographies and reported GMV totals are not interchangeable.
- Keep `review_id` and `(review_id, order_id)` distinctions. Never use `review_id` alone as a unique key.

## 6. Remaining original portfolio phases

| Phase | Work remaining | Status |
|---|---|---|
| Phase 4 — Power BI and Project 01 publication | Model, DAX, report, reconciliation, insights, screenshots, README and push to GitHub | **Next** |
| Phase 5 — Salesforce CRM | Generate clearly labelled synthetic CRM data, configure Salesforce objects, import leads/opportunities and create Salesforce reports | Planned |
| Phase 6 — Tableau CRM dashboard | Build calculated fields and sales-pipeline dashboard in Tableau Public | Planned |
| Phase 7 — GA4 funnel | Use Google's GA4 sample, BigQuery SQL and Looker Studio to analyse funnel drop-off | Planned |
| Phase 8 — Career packaging | GitHub Pages website, resume bullets based on measured results, LinkedIn descriptions and interview practice | Planned |

## 7. Phase 4 acceptance checklist

- [ ] Connect Power BI Desktop to PostgreSQL database `olist_analytics` using Import mode.
- [ ] Select the eight required `stg` tables; do not import `raw` tables.
- [ ] Keep the million-row geolocation table out of the first report model unless a specific visual requires it.
- [ ] Review Power Query data types, nulls and column names.
- [ ] Build and verify relationships; confirm fact-table grains before creating measures.
- [ ] Create a date table and DAX measures with explicit numerators, denominators and exclusions.
- [ ] Reconcile headline DAX values against existing SQL outputs, including all KPI caveats above.
- [ ] Build the four report pages and save the PBIX.
- [ ] Capture screenshots and document final findings, caveats and recommendations.
- [ ] Update Project 01 README and push the completed work to GitHub.

## 8. Immediate next action

Open Power BI Desktop and connect to PostgreSQL at `localhost:5432`, database `olist_analytics`, using **Import** mode. In Navigator, select only the eight listed `stg` tables (not `raw`, and not `stg.geolocation` for the first version). Choose **Transform Data**, then stop and review the selected tables before loading. The next working checkpoint is the Navigator/Power Query view, not another SQL analysis.

## 9. Preserved Project 01 working documents

The following four original working documents are included at `project-01-ecommerce/docs/` and supplemented append-only:

- `analysis_log.md`
- `data_quality_log.md`
- `data_dictionary.md`
- `methodology.md`
