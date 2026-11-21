# Project 01 — SQL Analysis Findings and Business Interpretation

**Status:** All seven SQL analysis files are completed.  
**Evidence basis:** The completed SQL files, original working documentation, SQL result screenshots and seven supplied visual summaries. Reported values are historical observed outputs, not projections.

## 1. Sales performance and payment methods — `01_sales_performance.sql`

**Status:** Completed.

### Findings
- 99,441 orders were placed; 96,478 were marked delivered (97.02%).
- Delivered item GMV was R$13,221,498.11 (R$13.22M); delivered freight value was R$2,198,275.64.
- Delivered item AOV was R$137.04.
- The reported monthly GMV peak was R$1,003,862.14 in November 2017. January–August 2018 monthly GMV ranged approximately R$837.9K–R$993.6K.
- Payment-method shares of total recorded payment value were: Credit Card 73.6%, Boleto 19.2%, Voucher 5.2%, Debit Card 1.9% and Other 0.1% (rounded visual values).

### Interpretation
The historical marketplace shows a substantial delivered-item GMV base. November 2017 was the highest reported monthly GMV month. Credit card payment value made up the largest share of recorded payment value in the supplied visual.

### Business implication
Track order volume and item value alongside GMV. Investigate the November 2017 peak using campaign, traffic or promotion data before attributing it to seasonality or marketing. Payment-method mix can inform checkout monitoring, but payment value share is not the same as order or customer share.

### Caveats and Power BI controls
- GMV is item price value; freight is separate. GMV/AOV are not marketplace net revenue or profit.
- Partial months should not be compared directly with full months.
- Query 3 calculates payment-method share using `SUM(payment_value)` / total `SUM(payment_value)`. An order may have multiple payment records and even multiple payment types.
- The completed sales SQL exposes both all-status item GMV and delivered-only item GMV in the monthly query. The executive monthly trend uses delivered-only item GMV. Match the exact existing SQL expression and status filter before reproducing each monthly series in DAX; do not treat the reported monthly GMV peak as automatically interchangeable with the delivered-only executive KPI.
- No result or business impact should be invented beyond the completed SQL outputs.

## 2. Data quality and reconciliation — `02_data_quality_investigations.sql`

**Status:** Completed.

### Findings
- 99,441 orders were examined; 98,665 had both item and payment records.
- 98,362 of 98,665 matched orders reconciled within R$0.01 (99.69%).
- 303 matched orders had an absolute discrepancy greater than R$0.01.
- 264 had recorded payment greater than item value plus freight; 39 had item value plus freight greater than payment.
- Average absolute difference was R$0.03; maximum absolute difference was R$182.81.
- Status split: 260 delivered + 2 canceled + 2 shipped in the payment-exceeds group; all 39 item-plus-freight-exceeds-payment exceptions were delivered.
- 775 orders lacked item records; one order lacked payment records; none lacked both. The 775 missing-item orders comprised 603 unavailable, 164 canceled, 5 created, 2 invoiced and 1 shipped.
- One delivered-status order lacked a payment record.
- 1,537 delivered item lines lacked an original category; 22 lacked an English category translation. No delivered item line lacked a matching product record.
- 789 repeated `review_id` groups represented 814 additional rows; the largest repeated-ID group had three rows. All repeated IDs spanned multiple orders; duplicate `(review_id, order_id)` groups were zero.

### Interpretation
Most matched transactions reconcile within the chosen tolerance. Exceptions are concentrated in delivered orders, but a discrepancy is not automatically a financial loss, overcharge or refund. Missing item rows are strongly concentrated in unavailable and canceled statuses, suggesting status-aware interpretation is necessary.

### Business implication
Maintain a documented reconciliation exception queue and status-based record-coverage checks. Keep item, freight and payment tables separate in the BI model. Preserve repeated review IDs unless the composite business key proves a true duplicate.

### Caveats
- Only orders with both item and payment data were eligible for the 98,665-order reconciliation denominator.
- The analysis does not establish why a discrepancy occurred.
- Category missingness and missing English translations should remain visible as data-quality indicators; do not silently discard item lines.

## 3. Delivery performance — `03_delivery_performance.sql`

**Status:** Completed.

### Findings
- 96,478 orders were marked delivered.
- 96,470 delivered-status orders formed the eligible delivery-analysis population with the required timestamps; eight delivered-status orders lacked an actual delivery timestamp.
- Six orders in other statuses had an actual delivery timestamp.
- Average delivery time was 12.56 calendar days.
- Calendar-date on-time delivery was 93.23%: 88,644 early and 1,292 on the estimated calendar date, out of 96,470 eligible orders (89,936 / 96,470).
- 6,534 deliveries were late (6.77% of eligible delivered orders).
- Late rates varied by customer state in the completed analysis.
- The executive KPI query separately reports 91.89% using timestamp-level comparison.

### Interpretation
Most eligible deliveries were early or on the estimated calendar date, but 6,534 arrived late. Delivery performance varied geographically.

### Business implication
Use the 93.23% calendar-date metric as the primary delivery dashboard KPI. Monitor late deliveries by customer state and investigate operational drivers with more granular carrier/seller/route data before prescribing interventions.

### Caveats
- Eight delivered-status orders without actual delivery timestamps were excluded from delivery-duration and on-time calculations. Do not reduce the delivered-status count of 96,478 to 96,470 in order reporting.
- Six orders in other statuses had a delivery timestamp; preserve and disclose these anomalies.
- The 91.89% timestamp-level result is a different KPI definition from 93.23% calendar-date comparison. Keep it separate and explicitly labelled; do not substitute it for the agreed 93.23% delivery-dashboard KPI.
- Geographic variation is descriptive and does not establish causation.

## 4. Customer analysis — `04_customer_analysis.sql`

**Status:** Completed.

### Findings
- 96,096 unique customers.
- 2,997 repeat customers; reported repeat-customer rate 3.12% (2,997 / 96,096).
- Order frequency: 93,099 customers with one order (96.88%); 2,745 with two orders; 203 with three; 30 with four; 19 with five or more.
- Repeat customers generated R$760,377.86 delivered item GMV.
- One-time customers generated R$12,461,120.25 delivered item GMV.
- The segment averages use only customers with delivered item GMV: 2,979 repeat customers and 90,379 one-time customers. Their reported averages were R$255.25 and R$137.88 respectively (approximately 1.85x).

### Interpretation
Most customers in the observed sample placed one order. Repeat customers had a higher average delivered item GMV per eligible customer than one-time customers.

### Business implication
A retention or repeat-purchase programme is a reasonable hypothesis for further testing. Use cohorts and campaign data to test whether interventions increase repeat purchasing; the current descriptive analysis does not establish incremental impact or lifetime value.

### Denominator clarification
The apparent difference between R$255.25 and dividing R$760,377.86 by all 2,997 repeat customers is explained by the segment-average denominator: only 2,979 repeat customers had delivered item GMV. Likewise, the one-time average uses 90,379 customers with delivered item GMV. The overall repeat-customer rate still uses all 2,997 repeat customers / 96,096 unique customers. This is resolved; DAX must preserve these different denominators.

### Caveats
- Repeat rate is based on the observed 2016–2018 period, not lifetime retention.
- Use `customer_unique_id` for person-level repeat analysis rather than order-level `customer_id`.
- Monthly first-time/repeat labels refer to earliest order observed in this dataset.
- September and October 2018 have very small order volumes; percentage swings in those months are unstable.
- State-level results are descriptive and do not establish causal relationships.
- Delivered item GMV excludes freight and does not represent profit or net company revenue.

## 5. Seller performance — `05_seller_performance.sql`

**Status:** Completed.

### Findings
- 2,970 sellers had delivered activity.
- Delivered item GMV was R$13.22M.
- Top 10 sellers contributed 13.27% of delivered item GMV; top five contributed 7.71%; the largest single seller contributed 1.72%.
- The top five displayed seller amounts were R$226,987.93; R$217,940.44; R$196,882.12; R$190,917.14; and R$186,570.05.
- São Paulo seller state had 1,769 active sellers and R$8,509,511.46 delivered item GMV.
- There were 16,068 seller-month combinations and 2,970 distinct sellers.

### Interpretation
Delivered GMV is spread across a broad seller base; the top ten contribute 13.27%, and the largest seller contributes 1.72%. São Paulo is the largest seller-state contribution in the supplied summary.

### Business implication
Monitor seller service and delivery alongside sales contribution. Avoid assigning incentives or risk labels based on GMV ranking alone; incorporate delivery, reviews and order volume.

### Caveats
- Seller-month rows are not unique sellers.
- Seller-state GMV is not customer-state GMV.
- Geographic concentration is descriptive, not causal.
- GMV is not seller profit or marketplace net revenue.

## 6. Product category performance — `06_product_category_performance.sql`

**Status:** Completed.

### Findings
- 74 product categories were represented.
- 110,197 delivered item lines were analysed.
- Top ten categories contributed 62.43% of delivered item GMV; top five contributed 39.83%; top 20 contributed 85.36%.
- Highest-GMV categories: Health & Beauty R$1.23M; Watches & Gifts R$1.17M; Bed, Bath & Table R$1.02M; Sports & Leisure R$0.95M; Furniture Decor R$0.71M.
- Bed, Bath & Table led item-line volume with 10,953 lines (9.94%).
- Furniture Decor's freight-to-item-value ratio was 23.65%; office furniture was 25.01% across 1,668 item lines and housewares was 23.19% across 6,795 lines.
- 1,537 item lines lacked an original category; 22 lacked an English translation. No delivered item line lacked a matching product record.

### Interpretation
A relatively small group of categories accounts for a large share of delivered item GMV. The highest-GMV category is not the same thing as the highest item-line volume category. Freight is a material relative component in some categories.

### Business implication
Review category assortment and inventory priorities using both GMV and item-line volume. Investigate freight burden for Furniture Decor and other high-ratio categories before changing shipping policy or assortment.

### Caveats
- Item lines are not necessarily units sold or unique orders.
- Average item price is line-weighted, not an order average.
- Freight-to-item-value is not a margin or profit measure.
- Category missingness must remain documented.

## 7. Executive KPI overview — `07_executive_kpi_overview.sql`

**Status:** Completed.

| KPI | Reported value |
|---|---:|
| Orders placed | 99,441 |
| Delivered-status orders | 96,478 (97.02%) |
| Delivered item GMV | R$13.22M |
| Delivered item freight | R$2.198M |
| Delivered item AOV | R$137.04 |
| Unique customers | 96,096 |
| Repeat customers | 2,997 (3.12%) |
| Sellers with delivered activity | 2,970 |
| Average delivery time | 12.56 days |
| Customer-state leaders | SP R$5.07M; RJ R$1.76M; MG R$1.55M; RS R$0.73M; PR R$0.67M |
| São Paulo customer-state volume | 40,494 delivered orders |
| Canceled / unavailable orders | 625 / 609 |

### Cross-analysis caveats and Power BI controls

1. Keep delivered-status order count (96,478) separate from valid-date delivery denominator (96,470).
2. Keep delivered item GMV and freight separate.
3. Do not present GMV/AOV as net revenue or profit.
4. Do not combine customer-state and seller-state geography.
5. Do not use seller-month combinations as a seller count.
6. Preserve source category nulls as data-quality items; avoid silent row removal.
7. Keep calendar-date (93.23%) and timestamp-level (91.89%) delivery KPIs separate.
8. Use 2,997 / 96,096 for repeat-customer rate, and use 2,979 / 90,379 as the segment-average customer denominators for R$255.25 and R$137.88.
9. Payment-method mix represents share of recorded payment value, not share of payment records/orders/customers.
10. Match the monthly GMV expression and status filter in the existing SQL before reusing the series in DAX.
11. The arithmetic sum of the nine raw table counts is 1,550,922; tables have different grains, so describe this only as total rows across the nine source tables.
