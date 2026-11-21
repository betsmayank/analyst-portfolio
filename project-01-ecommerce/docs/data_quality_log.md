
# Data Quality Log

This file records data issues and unusual patterns identified while exploring the Olist dataset.

## 1. Missing order records

During the initial data checks, I compared the orders table against the order items and payment tables to identify orders without corresponding records.

The database contains 99,441 orders.

| Record coverage | Orders |
|---|---:|
| Orders with both items and payments | 98,665 |
| Orders without item records | 775 |
| Orders without payment records | 1 |
| Orders missing both | 0 |

I also checked the status of orders without item records:

- Canceled: 164
- Unavailable: 603
- Created: 5
- Invoiced: 2
- Shipped: 1

Most missing item records belong to canceled or unavailable orders. These may be expected given the order lifecycle, rather than errors in the dataset.

For sales calculations, I will account for missing item records rather than treating every order as a completed sale.

## 2. Payment reconciliation

I compared the total product value and freight charges against the recorded payment value for each order.

The comparison covered 98,665 orders with both item and payment records.

A difference of up to R$0.01 was treated as acceptable.

| Result | Orders |
|---|---:|
| Reconciled | 98,362 |
| Payment higher than item value + freight | 264 |
| Item value + freight higher than payment | 39 |

The largest absolute difference was R$182.81. The average absolute difference across all eligible orders was R$0.03.

Most orders reconciled within the chosen tolerance. The remaining 303 orders need further investigation.

These differences have not been classified as confirmed payment errors. Their underlying causes have not yet been established.

## 3. Limited coverage in the final months

While reviewing monthly sales performance, I noticed a sharp drop in order volume towards the end of the dataset.

I checked the original orders table to see whether the decline was related to order status.

| Month | Total orders | Delivered | Canceled | Other statuses |
|---|---:|---:|---:|---:|
| August 2018 | 6,512 | 6,351 | 84 | 77 |
| September 2018 | 16 | 0 | 15 | 1 |
| October 2018 | 4 | 0 | 4 | 0 |

September had 15 canceled orders and one shipped order. All four October orders were canceled.

This means the final two months contain very little order activity and no delivered orders.

I will flag these months when presenting sales trends. The available data does not explain why activity declined, so I will not interpret this as an actual decline in business performance.

---

## Notes

- Missing records are not automatically invalid records.
- Payment differences require investigation before conclusions can be drawn.
- Periods with limited data coverage should be treated carefully when comparing sales performance.

---

Delivered orders with missing delivery timestamps

The dataset contains 96,478 orders marked as delivered. Of these, 96,470 have an actual customer delivery timestamp, while 8 are missing this field.

These 8 orders are excluded from delivery-time and delivery-performance calculations because their actual delivery dates are unavailable.

No delivered orders were found with an actual delivery timestamp earlier than the purchase timestamp. No estimated delivery dates were found earlier than the purchase timestamp.

This is a small data-completeness issue, not evidence that the orders were never delivered.


---

# Phase 3 completion addendum — expanded validation results

**Added:** 2026-11-21. The original investigation notes above are retained unchanged; this addendum adds the full status-level breakdown and clarifies eligibility and KPI definitions.

## 4. Order record coverage by status

The 99,441 orders were classified using distinct order IDs in `stg.order_items` and `stg.order_payments` before joining to `stg.orders`, preventing item/payment row multiplication.

| Order status | Both available | Missing items | Missing payments | Total in status |
|---|---:|---:|---:|---:|
| Approved | 2 | 0 | 0 | 2 |
| Canceled | 461 | 164 | 0 | 625 |
| Created | 0 | 5 | 0 | 5 |
| Delivered | 96,477 | 0 | 1 | 96,478 |
| Invoiced | 312 | 2 | 0 | 314 |
| Processing | 301 | 0 | 0 | 301 |
| Shipped | 1,106 | 1 | 0 | 1,107 |
| Unavailable | 6 | 603 | 0 | 609 |
| **Total** | **98,665** | **775** | **1** | **99,441** |

No order was missing both item and payment records. The missing-item concentration in unavailable and canceled statuses suggests order-lifecycle context is important; it does not prove that every missing item record is expected. The one order missing payment data is marked delivered and should remain an exception for investigation.

## 5. Payment reconciliation by order status

Signed difference = item GMV + freight − recorded payment. Negative means payment is higher; positive means item GMV plus freight is higher. Tolerance remains R$0.01.

| Order status | Reconciled | Payment exceeds | Item + freight exceeds |
|---|---:|---:|---:|
| Approved | 2 | 0 | 0 |
| Canceled | 459 | 2 | 0 |
| Delivered | 96,178 | 260 | 39 |
| Invoiced | 312 | 0 | 0 |
| Processing | 301 | 0 | 0 |
| Shipped | 1,104 | 2 | 0 |
| Unavailable | 6 | 0 | 0 |
| **Total** | **98,362** | **264** | **39** |

The 299 delivered-status exceptions represent 98.68% of all 303 reconciliation exceptions. This is a descriptive concentration only; it does not establish why the amounts differ or prove overcharging, refunds, losses or errors.

## 6. Review identifier pattern

- 789 `review_id` values occurred more than once.
- Those repeated-ID groups contained 814 additional rows beyond one row per ID.
- The maximum group size was three rows.
- All 789 repeated IDs spanned multiple orders.
- Duplicate `(review_id, order_id)` groups: **0**.

The composite pair is the validated review-order key in this source snapshot. Do not deduplicate on `review_id` alone.

## 7. Category mapping completeness

The category analysis reported 110,197 delivered item lines. All delivered item lines had a matching product record. However, 1,537 item lines lacked an original product category and 22 lacked an English category translation. The reported category completeness visual showed 98.4% with a category and 1.6% without. Missing classifications should remain visible in reporting rather than being silently dropped.

## 8. Delivery timestamp and on-time KPI controls

- 96,478 orders have `order_status = 'delivered'`.
- 96,470 have an actual customer delivery timestamp and form the delivered population used for delivery analysis with the corresponding estimated date.
- Eight delivered-status orders have no actual delivery timestamp.
- Six orders with a non-delivered status have an actual delivery timestamp.
- Calendar-date comparison counts actual delivery on or before the estimated calendar date as on time: 93.23% (89,936 / 96,470). This consists of 88,644 early, 1,292 on the estimated date and 6,534 late.
- The executive KPI's timestamp comparison reports 91.89%. It is a separate rule and must remain explicitly labelled; do not overwrite the calendar-date metric.

## 9. Reporting treatment

- Preserve raw and staging records; no rows were deleted as part of these investigations.
- Use explicit eligibility filters and denominators for each KPI.
- Exclude unavailable/canceled orders from delivered-item GMV only when the metric definition requires delivered orders; do not assume missing records are random.
- Keep reconciliation exceptions as investigation flags until transaction-level causes are established.
- Retain original-category and translation-missing cases as quality indicators.
