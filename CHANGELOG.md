# Changelog — Project 01 Documentation Package

**Date:** 2026-11-21

## Preserved

- All original text from the four uploaded working documents: `analysis_log.md`, `data_quality_log.md`, `data_dictionary.md` and `methodology.md`.
- The previous roadmap package's portfolio README, Project 01 README, requirements, roadmap, KPI dictionary, consolidated SQL findings and Phase 4 Power BI plan as the basis for the revised documents.
- Original working-document wording, findings, tables, notes, limitations and methodology decisions. The four original working documents are retained byte-for-byte as the prefix of their updated versions.

## Updated

- Portfolio README and Project 01 README: reflect all seven SQL analyses as complete and link to the four preserved working documents.
- Project 01 roadmap: seven-file completion register, data facts, remaining work and Phase 4 acceptance criteria.
- SQL findings: adds confirmed payment-method value shares; status-level data-quality and reconciliation findings; delivery KPI definitions; seller/category/exec results; and resolved repeat-customer average denominators.
- KPI dictionary: clarifies numerator/denominator, customer segment averages, payment-method value shares, separate delivery rates and distinct monthly GMV/delivered-only measures.
- Project 01 requirements: aligns functional requirements and acceptance criteria with the completed analyses.
- Phase 4 Power BI plan: aligns model scope, relationships, DAX measures, report pages and sign-off checks with the completed SQL and preserved working documents.

## Added to the four original working documents

- `analysis_log.md`: Phase 3 completion register and detailed sales/payment, delivery and executive KPI addendum; cross-references customer, seller and category findings already recorded in the original.
- `data_quality_log.md`: order-coverage-by-status table, reconciliation-by-status table, repeated review-ID investigation, category mapping completeness and delivery KPI distinctions.
- `data_dictionary.md`: staging-table grains, selected column definitions and PostgreSQL types, relationships, key/index constraints and KPI field mappings.
- `methodology.md`: ELT workflow, grain-first and join-fanout controls, quality rules, metric definitions and Power BI modelling method.
- `PACKAGE_MANIFEST.md` and `CHANGELOG.md`: auditable file list, integrity hashes and explicit scope/omission notes.

## Corrected or resolved points

1. Nine source table row counts sum to **1,550,922 rows** across different grains; this is not an order count.
2. **96,478 delivered-status orders** remain distinct from **96,470 eligible delivered orders with required delivery dates**.
3. **93.23% calendar-date on-time** and **91.89% timestamp-level on-time** remain separate metrics.
4. The customer repeat rate uses **2,997 / 96,096 = 3.12%**. The repeat-segment average R$255.25 uses **2,979** customers with delivered GMV; the one-time average R$137.88 uses **90,379** customers with delivered GMV. The apparent denominator mismatch is resolved.
5. Monthly GMV and delivered-only item GMV remain distinct until the exact completed SQL expression/status filter is matched in Power BI.
6. Payment method shares are reported as shares of total recorded payment value, not shares of orders or customers.

## Not changed / not included

- No completed SQL script was modified, replaced or packaged.
- No raw Olist CSV file or database dump was included.
- No Power BI report was fabricated; Phase 4 remains the next implementation phase.
