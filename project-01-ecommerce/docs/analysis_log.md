
# Analysis Log

This document records the main analytical questions explored during the Olist project, the SQL methods used, and the findings from each investigation.

## 1. Order and dataset profiling

**Objective:** Understand the size, coverage and composition of the dataset before performing sales analysis.

**Work completed:**
- Reviewed order status distribution.
- Checked purchase date coverage.
- Investigated repeated review IDs.
- Examined missing item and payment records.

**Key observations:**
- 99,441 orders in the staging orders table.
- Dataset purchase dates range from September 2016 to October 2018.
- 775 orders have no item records.
- 1 order has no payment record.

## 2. Sales performance

**Objective:** Understand monthly sales activity, product category performance and payment behaviour.

**Work completed:**
- Monthly sales performance.
- Product category ranking by delivered GMV.
- Payment method distribution.
- Order-level payment reconciliation.

Detailed findings and metric definitions will be added as each analysis is finalised.

## 3. Customer Behaviour and Repeat Purchasing

### Objective

Understand customer purchasing frequency, identify repeat customers, compare the contribution of one-time and repeat customers to delivered item GMV, and examine differences in repeat purchasing across customer states.

### Data and methodology

The analysis used the `stg.orders` and `stg.customers` tables, joined through `customer_id`.

Customer identification was based on `customer_unique_id`, rather than `customer_id`, because the unique identifier allows multiple order records associated with the same underlying customer to be grouped together.

Five analyses were performed:

1. Classified customers as one-time or repeat customers based on their observed order count.
2. Examined the distribution of customers by number of observed orders.
3. Compared monthly first-time and repeat-customer order volumes.
4. Compared delivered item GMV between one-time and repeat customers.
5. Compared repeat-customer rates across customer states, excluding states with fewer than 100 identified customers.

A repeat customer was defined as someone with more than one observed order in the available dataset. Delivered item GMV was calculated using item prices from delivered orders, excluding freight.

### Key findings

#### A. Overall repeat purchasing

The dataset contained 96,096 unique identified customers associated with 99,441 orders.

| Customer classification | Customers |
|---|---:|
| One-time customers | 93,099 |
| Repeat customers | 2,997 |
| Total unique customers | 96,096 |

The observed repeat-customer rate was 3.12%, while 96.88% of customers had only one observed order.

This indicates that repeat purchasing represents a relatively small share of the observed customer base.

#### B. Distribution of purchase frequency

| Observed orders per customer | Customers | Share |
|---|---:|---:|
| 1 order | 93,099 | 96.88% |
| 2 orders | 2,745 | 2.86% |
| 3 orders | 203 | 0.21% |
| 4 orders | 30 | 0.03% |
| 5 or more orders | 19 | 0.02% |

Most repeat customers placed exactly two orders. Only a small number placed three or more orders within the available dataset period.

#### C. Monthly first-time and repeat-customer orders

Monthly repeat-customer order shares generally remained around 3–4% during the main period of substantial order activity.

Examples include:

| Month | Total orders | Repeat-customer orders | Repeat-order share |
|---|---:|---:|---:|
| January 2017 | 800 | 36 | 4.50% |
| September 2017 | 4,285 | 155 | 3.62% |
| February 2018 | 6,728 | 277 | 4.12% |
| May 2018 | 6,873 | 251 | 3.65% |
| August 2018 | 6,512 | 241 | 3.70% |

September 2018 recorded an apparent repeat-order share of 68.75%, and October 2018 recorded 75%. However, these months contained only 16 and 4 orders respectively. The percentages are therefore based on very small populations and should not be interpreted as evidence of a sudden improvement in customer retention.

#### D. Delivered item GMV by customer type

| Metric | One-time customers | Repeat customers |
|---|---:|---:|
| Customer count | 93,099 | 2,997 |
| Customers with delivered item GMV | 90,379 | 2,979 |
| Delivered item GMV | R$12,461,120.25 | R$760,377.86 |
| Average delivered item GMV per customer with delivered GMV | R$137.88 | R$255.25 |

Repeat customers had approximately 1.85 times the average delivered item GMV per customer compared with one-time customers.

Although repeat customers represented only 3.12% of identified customers, they contributed R$760,377.86 in delivered item GMV.

This suggests that customers who made multiple observed purchases had a higher average merchandise value within the dataset.

#### E. Repeat purchasing by customer state

Repeat-customer rates varied across the 24 states returned by the analysis.

The highest observed rates included:

| State | Unique customers | Repeat customers | Repeat rate |
|---|---:|---:|---:|
| RO | 240 | 10 | 4.17% |
| RJ | 12,384 | 421 | 3.40% |
| MT | 876 | 29 | 3.31% |
| GO | 1,952 | 64 | 3.28% |
| SP | 40,302 | 1,296 | 3.22% |

The lowest observed rates included CE (1.68%), PE (2.05%) and AM (2.10%).

RO had the highest percentage, but its customer population was much smaller than RJ or SP. State-level comparisons should therefore consider the underlying customer counts, not just the percentages.

### Business interpretation

The analysis identifies a low observed repeat-purchase rate across the customer base. It also shows that customers with multiple observed purchases generated higher average delivered item GMV than customers with only one observed purchase.

This creates a potential area for further investigation into customer retention and repeat purchasing.

However, the analysis does not establish why customers returned, whether repeat purchasing was driven by customer experience, product category, pricing, delivery performance or other factors.

### Limitations

- The dataset covers a limited historical period. A customer with one observed order may have purchased before or after the available period.
- Repeat purchasing is measured only within the observed dataset and should not be interpreted as complete customer lifetime behaviour.
- Monthly first-time and repeat classifications use the earliest order observed in the dataset.
- The monthly percentages for September and October 2018 are based on very small order volumes.
- State-level results are descriptive and do not establish causal relationships.
- Delivered item GMV excludes freight and does not represent profit or net company revenue.
- Average delivered item GMV per customer is calculated only among customers with delivered item GMV.

### Conclusion

Customer purchasing in the observed dataset was heavily concentrated among one-time customers. Repeat customers represented a small proportion of the identified customer base but had a higher average delivered item GMV per customer.

The results provide a useful baseline for understanding customer purchasing behaviour and identifying potential retention opportunities. Further analysis would be needed to understand the factors associated with repeat purchasing.

----

## 4. Seller Performance

### Objective

Evaluate seller performance across the Olist marketplace by examining delivered item GMV, sales concentration, geographic distribution and monthly seller activity.

The analysis aims to understand how sales are distributed among sellers and whether marketplace performance is concentrated among particular sellers or states.

### Data and methodology

The analysis used the following staging tables:

- `stg.order_items`
- `stg.orders`
- `stg.sellers`
- `stg.customers`

Only orders with `order_status = 'delivered'` were included in the seller sales analysis.

Seller performance was measured using delivered item GMV, calculated as the sum of item prices. Freight was excluded.

The analysis contained four parts:

1. Seller-level delivered sales performance.
2. Delivered item GMV concentration across sellers.
3. Seller performance grouped by seller state.
4. Monthly delivered sales activity by seller.

A seller-order combination was treated as the unit of seller-level order activity. This is important because a single customer order can contain items from multiple sellers.

### Key findings

#### 1. Seller-level delivered sales performance

The seller-level analysis returned 2,970 sellers with delivered sales.

The five highest-ranked sellers by delivered item GMV were:

| Rank | Seller state | Delivered item GMV |
|---|---|---:|
| 1 | SP | R$226,987.93 |
| 2 | BA | R$217,940.44 |
| 3 | SP | R$196,882.12 |
| 4 | SP | R$190,917.14 |
| 5 | SP | R$186,570.05 |

The highest-ranked seller recorded:

- 1,124 delivered seller-orders.
- 1,117 distinct customers.
- 1,148 delivered item lines.
- R$226,987.93 delivered item GMV.
- R$201.95 average delivered item GMV per seller-order.

São Paulo appeared frequently among the highest-ranked sellers, although the second-ranked seller was based in Bahia.

#### 2. Delivered item GMV concentration among sellers

The concentration analysis calculated each seller's percentage contribution to total delivered item GMV and the cumulative contribution of sellers ranked by sales value.

The top ten sellers contributed the following cumulative shares:

| Seller ranking | Individual GMV share | Cumulative GMV share |
|---|---:|---:|
| 1 | 1.72% | 1.72% |
| 2 | 1.65% | 3.37% |
| 3 | 1.49% | 4.85% |
| 4 | 1.44% | 6.30% |
| 5 | 1.41% | 7.71% |
| 6 | 1.26% | 8.96% |
| 7 | 1.21% | 10.17% |
| 8 | 1.06% | 11.23% |
| 9 | 1.05% | 12.28% |
| 10 | 1.00% | 13.27% |

No individual seller contributed more than 1.72% of delivered item GMV.

The top ten sellers together accounted for 13.27% of delivered item GMV. This suggests that sales value is distributed across a broad seller base rather than being dominated by the ten largest sellers.

A broader concentration analysis involving the top 50 or 100 sellers could provide additional detail.

#### 3. Seller performance by state

The state-level analysis returned 22 states with sellers generating delivered sales.

São Paulo had the largest seller base and the highest total delivered item GMV.

| State | Active sellers | Delivered seller-orders | Delivered item GMV |
|---|---:|---:|---:|
| SP | 1,769 | 69,401 | R$8,509,511.46 |
| PR | 335 | 7,556 | R$1,232,096.99 |
| MG | 236 | 7,747 | R$977,866.31 |
| RJ | 163 | 4,229 | R$820,611.59 |
| SC | 184 | 3,608 | R$613,591.65 |

The results show a substantial concentration of seller activity and delivered item GMV in São Paulo.

Average delivered item GMV per seller presented a different ranking:

| State | Active sellers | Average GMV per seller |
|---|---:|---:|
| MA | 1 | R$36,097.98 |
| BA | 18 | R$15,440.31 |
| PE | 9 | R$10,129.35 |
| RJ | 163 | R$5,034.43 |
| SP | 1,769 | R$4,810.51 |

The difference between total GMV and average GMV per seller highlights two distinct aspects of marketplace performance: overall scale and average seller contribution.

The high average for Maranhão is based on a single active seller, so it should not be interpreted as evidence of generally higher seller productivity in that state.

#### 4. Monthly seller performance

The monthly analysis returned 16,068 seller-month records across 17 result pages.

Each row represented one seller's delivered sales activity in a particular purchase month.

The analysis included:

- Seller ID.
- Purchase month.
- Number of delivered orders.
- Number of delivered item lines.
- Delivered item GMV.

This provides a dataset for examining individual seller activity over time and can support further analysis of seller growth, inactivity and sales consistency.

The result count represents seller-month combinations, not unique sellers or unique orders.

### Business interpretation

The analysis indicates that the Olist marketplace has a broad seller base, with 2,970 sellers generating delivered sales.

Although São Paulo dominates total seller activity and delivered item GMV, the state-level averages show that seller productivity and marketplace scale are not the same measure.

The top ten sellers contribute 13.27% of delivered item GMV, suggesting that the marketplace is not heavily dependent on only a handful of top sellers.

These findings can help identify high-performing sellers, understand geographic concentration and establish a baseline for monitoring seller activity.

### Limitations

- Only delivered orders were included in the seller sales calculations.
- Delivered item GMV excludes freight and does not represent seller profit, marketplace revenue or net revenue.
- One customer order can involve multiple sellers. Seller-order counts therefore should not be interpreted as unique marketplace orders.
- Seller-state comparisons are descriptive and do not establish why sales differ between states.
- Average GMV per seller can be misleading when a state has very few active sellers.
- The monthly dataset contains seller-month combinations, and its row count should not be confused with the number of unique sellers.
- The analysis does not account for seller operating costs, commissions, margins or other expenses.

### Conclusion

The seller analysis identified a broad base of 2,970 sellers with delivered sales and found that the top ten sellers contributed 13.27% of delivered item GMV.

São Paulo dominated total seller activity and sales value, while some smaller states showed higher average GMV per seller. These differences demonstrate why total sales and average seller performance should be evaluated separately.

The monthly seller-level output provides a foundation for further investigation into seller activity and performance over time.

## 5. Product Category Performance

**Objective:** Evaluate delivered sales performance across product categories, identify high-volume and high-GMV categories, examine GMV concentration, assess freight burden and investigate category-mapping completeness.

### 1. Category performance

- 74 product categories were returned.
- Health and beauty generated the highest delivered item GMV at R$1,233,131.72.
- Watches and gifts ranked second at R$1,166,176.98.
- Bed, bath and table ranked third at R$1,023,434.76.
- Computers had the highest average item price among the displayed categories at R$1,098.92, but only 199 delivered item lines.

### 2. Category volume

- Bed, bath and table had the highest delivered item volume, with 10,953 item lines (9.94%).
- Health and beauty followed with 9,465 item lines (8.59%).
- Sports and leisure ranked third with 8,431 item lines (7.65%).

The category leading in item volume was different from the category leading in GMV.

### 3. GMV concentration

- Top 5 categories accounted for 39.83% of delivered item GMV.
- Top 10 categories accounted for 62.43%.
- Top 20 categories accounted for 85.36%.

This indicates that delivered item GMV was concentrated among a relatively small number of product categories.

### 4. Freight burden

- Several smaller categories showed high freight-to-item-value ratios.
- Among categories with more substantial volume, office furniture had a ratio of 25.01% across 1,668 item lines.
- Furniture decor had a ratio of 23.65% across 8,160 item lines.
- Housewares had a ratio of 23.19% across 6,795 item lines.

Freight-to-item-value is a relative freight burden indicator, not a profit-margin measure.

### 5. Category data quality

- Total delivered item lines: 110,197.
- Item lines without a matching product: 0.
- Item lines without an original category: 1,537.
- Item lines without an English translation: 22.
- Delivered item GMV associated with missing English translations or category labels: R$175,967.21.

The missing category labels affect classification and reporting, but all delivered item lines matched a product record.

### Key takeaway

Delivered item GMV was concentrated in the leading product categories, while item volume and GMV rankings differed. Freight burden varied across categories, and category-label completeness remains a minor reporting limitation.

**Limitations:** The analysis covers delivered orders only. GMV excludes freight. Freight-to-item-value does not measure profitability. Category performance is descriptive and does not establish causation.



---

# Phase 3 completion addendum — seven SQL analyses

**Added:** 2026-11-21  
**Purpose:** Record the completed state of the seven SQL analyses and carry verified results into Power BI planning. This addendum supplements the original analysis notes above. The original text, including earlier forward-looking notes, is retained for project history. The detailed customer, seller and product-category analyses in Sections 3–5 above remain the primary working records for those topics.

## A. Completed analysis register

| # | Analysis | Existing SQL file | Status |
|---:|---|---|---|
| 01 | Sales performance and payment methods | `01_sales_performance.sql` | Completed |
| 02 | Data quality and reconciliation | `02_data_quality_investigations.sql` | Completed |
| 03 | Delivery performance | `03_delivery_performance.sql` | Completed |
| 04 | Customer analysis | `04_customer_analysis.sql` | Completed |
| 05 | Seller performance | `05_seller_performance.sql` | Completed |
| 06 | Product category performance | `06_product_category_performance.sql` | Completed |
| 07 | Executive KPI overview | `07_executive_kpi_overview.sql` | Completed |

The seven existing SQL files are complete and remain the source of truth for exact query logic and filters. This documentation update does not create, replace or edit SQL scripts.

## B. Sales performance and payment methods

- The executive snapshot reports **99,441 orders placed**, **96,478 delivered-status orders (97.02%)**, **R$13,221,498.11 delivered item GMV**, **R$2,198,275.64 delivered freight value**, and **R$137.04 delivered item AOV**.
- The reported monthly GMV peak is **R$1,003,862.14 in November 2017**. The reported January–August 2018 monthly range is approximately **R$837.9K–R$993.6K**. Partial first/last months must be flagged.
- Payment-method shares shown in the supplied sales visual are shares of **total recorded payment value**, consistent with Query 3 in `01_sales_performance.sql` (`SUM(payment_value)` divided by total payment value): Credit Card **73.6%**, Boleto **19.2%**, Voucher **5.2%**, Debit Card **1.9%**, and Other **0.1%**. These are value shares, not necessarily shares of orders or customers. One order can have multiple payment records and payment types.
- The completed sales SQL exposes monthly item GMV across statuses and delivered-only item GMV as distinct measures. The executive monthly trend is delivered-only. Do not collapse these into one DAX measure. Match each Power BI series to the exact existing SQL expression and status filter.

## C. Data quality and payment reconciliation

The 99,441 orders were classified by whether corresponding item and payment records existed. **98,665** had both; **775** had item records missing only; **1** had payment records missing only; **0** were missing both. The 775 missing-item orders were concentrated in unavailable (603) and canceled (164) statuses, with 5 created, 2 invoiced and 1 shipped.

Among the 98,665 orders with both item and payment data, **98,362 (99.69%)** reconciled within R$0.01 and **303** exceeded the tolerance. Of the exceptions, **264** had payment above item GMV plus freight and **39** had item GMV plus freight above payment. Average absolute difference was **R$0.03** and maximum absolute difference was **R$182.81**. Status-level analysis found 260 payment-higher and 39 item-plus-freight-higher exceptions among delivered orders; two additional payment-higher cases were canceled and two were shipped. Exceptions are investigation flags, not confirmed losses, refunds or overcharges.

The review data contained **789 repeated `review_id` groups**, representing 814 additional rows, with at most three rows per repeated ID. All repeated IDs spanned multiple orders; duplicate `(review_id, order_id)` groups were zero. Do not deduplicate on `review_id` alone.

## D. Delivery performance

- Orders marked delivered: **96,478**.
- Delivered-status orders with valid delivery timestamps for the delivery analysis: **96,470**. Eight delivered-status orders lacked an actual delivery timestamp.
- Six orders in other statuses had an actual delivery timestamp; preserve this anomaly rather than silently changing their status.
- Average delivery time: **12.56 calendar days**.
- Calendar-date on-time rate: **93.23%**, comprising 88,644 early deliveries and 1,292 delivered on the estimated calendar date, out of 96,470 eligible delivered orders. Late deliveries: **6,534 (6.77%)**.
- The executive KPI query separately reports **91.89%** using timestamp-level comparison (`actual_delivery_timestamp <= estimated_delivery_timestamp`). Keep the 91.89% and 93.23% definitions separate. Use 93.23% as the agreed delivery-dashboard KPI because the delivery analysis treats any delivery on the estimated calendar date as on time. Do not substitute one value for the other.
- State-level delivery comparisons are descriptive and do not establish causes.

## E. Customer denominator clarification

The existing customer analysis reports **96,096 unique customers**, **2,997 repeat customers**, and a **3.12% repeat-customer rate** (2,997 / 96,096). For delivered-GMV-per-customer averages, the segment denominator is narrower: **2,979 repeat customers with delivered item GMV** and **90,379 one-time customers with delivered item GMV**. Therefore:

- Repeat segment: R$760,377.86 / 2,979 = approximately **R$255.25** per customer with delivered GMV.
- One-time segment: R$12,461,120.25 / 90,379 = approximately **R$137.88** per customer with delivered GMV.
- The reported ratio is approximately **1.85x**.

This resolves the apparent mismatch between R$255.25 and division by all 2,997 repeat customers. Do not use 2,997 as the denominator for the segment average; 2,997 remains the denominator's population count for the overall repeat-customer rate. The historical observed repeat rate is not lifetime retention.

## F. Seller, category and executive summary cross-reference

The detailed seller results remain in Section 4 above and `05_seller_performance.sql`; the 2,970 sellers with delivered activity contributed R$13.22M delivered item GMV. Top ten sellers contributed 13.27%, top five 7.71%, and the largest seller 1.72%. Seller-month records are combinations, not unique sellers. São Paulo seller-state results must not be confused with customer-state results.

The detailed category results remain in Section 5 above and `06_product_category_performance.sql`: 74 categories, 110,197 delivered item lines, top 10 category share 62.43%, top 5 share 39.83%, top 20 share 85.36%; Bed, Bath & Table led item-line volume with 10,953 (9.94%). Category missingness and freight burden remain documented in `data_quality_log.md` and `sql_analysis_findings.md`.

The executive snapshot reports 96,096 unique customers, 2,997 repeat customers (3.12%), 2,970 active sellers, 12.56 average delivery days, customer-state delivered GMV leaders SP R$5.07M, RJ R$1.76M, MG R$1.55M, RS R$0.73M and PR R$0.67M, and 625 canceled / 609 unavailable orders.

## G. Power BI sign-off controls

1. Keep 96,478 delivered-status orders separate from 96,470 eligible delivered orders with valid dates.
2. Keep 93.23% calendar-date on-time separate from 91.89% timestamp-level on-time.
3. Use 2,997 repeat customers for repeat rate; use 2,979 repeat customers with delivered GMV for the R$255.25 segment average.
4. Keep monthly GMV series and delivered-only item GMV distinct until their SQL expression/filter is explicitly matched.
5. Keep item GMV, freight and recorded payment value separate.
6. Keep customer-state and seller-state geography separate.
7. Do not treat seller-month records as unique sellers or item lines as unique orders/units.
8. Do not infer causation, marketplace profit, net revenue, customer lifetime value or financial loss from these descriptive outputs.
