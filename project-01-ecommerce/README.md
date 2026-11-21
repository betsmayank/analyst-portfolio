# Project 01: E-commerce Business Performance & Customer Experience

**Status:** Seven SQL analysis files complete; Power BI semantic model and dashboard are next.  
**Dataset:** Olist Brazilian E-Commerce Public Dataset, 2016–2018.  
**Tools:** PostgreSQL 18, pgAdmin 4, SQL, Power BI Desktop, DAX, GitHub.

## Business problem

An online marketplace operations team needs to understand product GMV, order trends, repeat purchasing, seller/category mix, delivery performance and data quality to prioritise commercial and operational improvements.

## Data source and scope

The Olist dataset contains anonymised Brazilian marketplace records from 2016–2018. Source: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce. Licence: CC BY-NC-SA 4.0. Raw source files are not included in this repository; follow the documented setup and import steps.

Nine source tables were imported into PostgreSQL. Their row counts sum to **1,550,922 rows across different table grains**, not 1,550,922 orders. The `raw` layer preserves source values; the `stg` layer contains typed tables for analysis.

## Completed SQL analyses

| SQL file | Analysis | Status |
|---|---|---|
| `01_sales_performance.sql` | Sales performance and payment methods | Complete |
| `02_data_quality_investigations.sql` | Data coverage, key checks and payment reconciliation | Complete |
| `03_delivery_performance.sql` | Delivery duration, on-time/late performance and geography | Complete |
| `04_customer_analysis.sql` | Unique and repeat customers, order frequency and segment GMV | Complete |
| `05_seller_performance.sql` | Seller GMV, concentration and seller-state contribution | Complete |
| `06_product_category_performance.sql` | Category GMV, item-line volume, concentration and freight burden | Complete |
| `07_executive_kpi_overview.sql` | Consolidated executive KPI snapshot | Complete |

Do not repeat these analyses or create duplicate SQL files. Use their outputs as the source of truth for Power BI measure reconciliation. The seven SQL scripts are intentionally not included in the documentation update ZIP and are not modified by it.

## Key findings from completed outputs

- **Executive snapshot:** 99,441 orders placed; 96,478 marked delivered (97.02%); R$13,221,498.11 delivered item GMV; R$2,198,275.64 delivered freight; R$137.04 delivered item AOV; 96,096 unique customers; 2,997 repeat customers (3.12%); 2,970 sellers with delivered activity; 12.56 days average delivery time.
- **Sales:** The reported monthly GMV peak was R$1,003,862.14 in November 2017. January–August 2018 monthly GMV ranged approximately R$837.9K–R$993.6K. Partial months must be flagged. The completed SQL exposes all-status and delivered-only monthly measures; match the existing expression and status filter before reproducing a specific monthly series in DAX.
- **Payment methods:** The supplied sales visual reports shares of recorded payment value: Credit Card 73.6%, Boleto 19.2%, Voucher 5.2%, Debit Card 1.9% and Other 0.1%. These are not order/customer shares. One order can contain multiple payment rows and payment types.
- **Data quality:** 98,665 orders had both item and payment records. 98,362 reconciled within R$0.01 (99.69%); 303 did not. Of these, 264 had payment above item value plus freight and 39 had item value plus freight above payment. The maximum absolute difference was R$182.81; average absolute difference was R$0.03.
- **Record coverage:** 775 orders lacked item records, one lacked payment records and none lacked both. The 775 missing-item orders comprised 603 unavailable, 164 canceled, 5 created, 2 invoiced and 1 shipped. The one missing-payment order was delivered.
- **Delivery:** 96,478 orders were marked delivered; 96,470 had valid dates for delivery analysis. Average delivery time was 12.56 days. Calendar-date on-time delivery was 93.23% (89,936 / 96,470); 6,534 orders (6.77%) were late. Eight delivered-status orders lacked an actual delivery timestamp; six orders in other statuses had one.
- **Alternate delivery KPI:** The executive query reports 91.89% using timestamp-level comparison. This differs from the 93.23% calendar-date metric, which counts same-calendar-date delivery as on time. The delivery dashboard should use 93.23%; keep 91.89% separate and explicitly labelled if shown.
- **Customers:** 96,096 unique customers; 2,997 repeat customers (3.12%). Repeat customers generated R$760,377.86 delivered item GMV. The R$255.25 average is calculated across 2,979 repeat customers with delivered GMV, not all 2,997 repeat customers. One-time customers with delivered GMV: 90,379; their average was R$137.88. The reported segment-average ratio is 1.85x.
- **Sellers:** 2,970 sellers had delivered activity. The top 10 sellers contributed 13.27% of delivered item GMV; the top five contributed 7.71%; the largest seller contributed 1.72%. São Paulo seller state had 1,769 active sellers and R$8.51M delivered item GMV.
- **Categories:** 74 categories and 110,197 delivered item lines. Top 10 categories contributed 62.43% of delivered item GMV; top five 39.83%; top 20 85.36%. Health & Beauty led at R$1.23M. Bed, Bath & Table led line volume with 10,953 lines (9.94%). Furniture Decor freight-to-item-value ratio was 23.65%.
- **Geography:** Top customer states by delivered item GMV were SP R$5.07M, RJ R$1.76M, MG R$1.55M, RS R$0.73M and PR R$0.67M. Customer-state and seller-state geography are different measures.

## Business interpretation and recommendations

1. **Protect reporting reliability:** Keep item GMV, freight and payment amounts separately defined. Route the 303 reconciliation exceptions for transaction-level review; do not call them losses or customer overcharges without evidence.
2. **Segment order completeness by status:** Most missing item records are in unavailable and canceled statuses. Apply the metric's explicit eligibility rule rather than treating all missing items as random corruption.
3. **Prioritise delivery monitoring:** Use the 93.23% calendar-date on-time metric as the delivery dashboard KPI and track 6,534 late deliveries by customer state. The analysis is descriptive, not causal.
4. **Investigate customer retention:** The observed repeat-customer rate is 3.12%. A retention initiative is a hypothesis to test; the historical analysis does not establish lifetime value or campaign ROI.
5. **Monitor category and freight mix:** The top 10 categories contribute 62.43% of delivered item GMV. Review category dependence and freight burden, especially Furniture Decor, without interpreting freight ratio as profit margin.
6. **Monitor seller contribution and service:** Seller GMV is not highly concentrated in the top 10 (13.27%). Pair seller contribution with delivery and review metrics before changing seller allocation or incentives.

## KPI and definition controls

- Delivered orders (96,478) are not the same as eligible delivered orders with valid delivery dates (96,470).
- The agreed delivery dashboard on-time KPI is **93.23% by calendar date**. The separate **91.89% timestamp-level** metric must remain explicitly labelled.
- Delivered item GMV is R$13,221,498.11; freight is R$2,198,275.64 and must remain separate. Delivered item AOV is R$137.04 using the delivered orders with item rows.
- Repeat-customer rate uses 2,997 / 96,096. Segment average delivered GMV per customer uses the narrower eligible denominators 2,979 repeat and 90,379 one-time customers with delivered GMV.
- Keep the monthly GMV series distinct from delivered-only item GMV; use the existing SQL filter/column for each chart rather than forcing a single definition.
- Payment-method percentages are shares of payment value, not order counts or customer counts.

## Limitations

- The dataset is historical and specific to an anonymised Brazilian marketplace from 2016–2018; it is not current evidence for India or Europe.
- GMV and AOV are item-value measures, not marketplace net revenue, profit or contribution margin. Product cost and operating cost data are not provided.
- Partial first/last months are not comparable to full months without qualification.
- Delivery calculations exclude eight delivered-status orders without actual delivery timestamps. Six non-delivered statuses have delivery timestamps; these anomalies are preserved and disclosed.
- Calendar-date on-time (93.23%) and timestamp-level on-time (91.89%) use different comparison logic; they must not be merged.
- The 303 payment reconciliation exceptions are investigation flags, not confirmed financial losses, refunds or overcharges.
- Repeated `review_id` values are not sufficient grounds for deduplication: 789 repeated-ID groups were observed, while duplicate `(review_id, order_id)` groups were zero.
- Descriptive state/category/seller comparisons do not demonstrate causation.

## Project documentation

- [`docs/analysis_log.md`](docs/analysis_log.md): original analysis notes plus completed Phase 3 addendum.
- [`docs/data_quality_log.md`](docs/data_quality_log.md): original data-quality investigations plus status-level reconciliation and delivery-date checks.
- [`docs/data_dictionary.md`](docs/data_dictionary.md): source/staging table grains, data types and analytical field definitions.
- [`docs/methodology.md`](docs/methodology.md): ELT workflow, grain and join decisions, and Power BI controls.
- [`docs/sql_analysis_findings.md`](docs/sql_analysis_findings.md): consolidated findings and business interpretation.
- [`docs/phase_4_powerbi_plan.md`](docs/phase_4_powerbi_plan.md): remaining Power BI implementation plan.
- [`../docs/kpi_dictionary.md`](../docs/kpi_dictionary.md): cross-project KPI definitions.
- [`../docs/project_01_roadmap.md`](../docs/project_01_roadmap.md): Project 01 status and next steps.

## Next phase: Power BI

See [`docs/phase_4_powerbi_plan.md`](docs/phase_4_powerbi_plan.md) and the portfolio-level [Project 01 roadmap](../docs/project_01_roadmap.md). The immediate task is to connect Power BI Desktop to PostgreSQL, import the selected staging tables and validate the data model. No additional SQL analysis is planned at this checkpoint.

## Reproduction

1. Download the Olist dataset from Kaggle and review its CC BY-NC-SA 4.0 terms.
2. Install PostgreSQL 18 and pgAdmin 4.
3. Follow the existing SQL import and staging scripts in `sql/`.
4. Use the seven completed analysis files as the source of truth for the reported results and exact query filters.
5. Connect Power BI to PostgreSQL database `olist_analytics` and select the documented staging tables only.

Raw CSV files and database credentials must not be committed to GitHub.
