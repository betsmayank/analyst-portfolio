# Documentation Package Manifest

**Package:** Project 01 — Complete Documentation Update  
**Created:** 2026-11-21  
**Purpose:** Merge the seven-file roadmap update with the four original Project 01 working documents supplied by the project owner.

## Archive summary

- **13 regular files** are included.
- This is a documentation merge overlay for the existing repository root, not a full repository backup. Merge/overwrite only the listed documentation paths; do not delete unlisted project files or folders.
- The archive includes directory entries for `docs/`, `project-01-ecommerce/` and `project-01-ecommerce/docs/` (directory entries are not counted as files).
- The four supplied original working documents are placed under the requested `project-01-ecommerce/docs/` path.
- The seven completed SQL scripts are **intentionally omitted** from this documentation-only ZIP; no SQL script is modified or replaced.
- Raw CSV source data and database credentials are also intentionally omitted.

## Complete regular-file manifest

| # | Path | Classification |
|---:|---|---|
| 1 | `README.md` | Updated portfolio README |
| 2 | `docs/kpi_dictionary.md` | Updated cross-project KPI dictionary |
| 3 | `docs/project_01_requirements.md` | Updated Project 01 requirements |
| 4 | `docs/project_01_roadmap.md` | Updated roadmap and phase status |
| 5 | `project-01-ecommerce/README.md` | Updated Project 01 README |
| 6 | `project-01-ecommerce/docs/sql_analysis_findings.md` | Updated consolidated seven-analysis findings |
| 7 | `project-01-ecommerce/docs/phase_4_powerbi_plan.md` | Updated Power BI implementation plan |
| 8 | `project-01-ecommerce/docs/analysis_log.md` | Original working document preserved and supplemented |
| 9 | `project-01-ecommerce/docs/data_dictionary.md` | Original working document preserved and supplemented |
| 10 | `project-01-ecommerce/docs/data_quality_log.md` | Original working document preserved and supplemented |
| 11 | `project-01-ecommerce/docs/methodology.md` | Original working document preserved and supplemented |
| 12 | `CHANGELOG.md` | Package change and preservation record |
| 13 | `PACKAGE_MANIFEST.md` | This manifest and verification record |

## Original-document integrity checks

The four supplied originals were extracted from `project-01-ecommerce-docs.zip`. Their ZIP member names used Windows backslashes (`docs\name.md`); the final package normalises them to the requested forward-slash path under `project-01-ecommerce/docs/`.

The original byte content of each document is retained verbatim as the beginning of the final file. Only an appended Phase 3 completion addendum follows the original content. SHA-256 of each original source payload:

| Final path | Preservation treatment | SHA-256 of original bytes |
|---|---|
| `project-01-ecommerce/docs/analysis_log.md` | Preserved original + appended update | `1476e1c9c715ccc1491600185a97187d1660844042226957ede4cbe5be061984` |
| `project-01-ecommerce/docs/data_dictionary.md` | Preserved original + appended update | `c9e8e030958130d1ccf4ca5e89d3962e5c32301785d1e15c38316cf2ddcf5b21` |
| `project-01-ecommerce/docs/data_quality_log.md` | Preserved original + appended update | `95e95eaf0812377bcc5c537175daf78f9b7cf04d5af7d69fff8681c2495028bd` |
| `project-01-ecommerce/docs/methodology.md` | Preserved original + appended update | `aa1e366e86090d2ef76a39288c1e8774f60cfa621b029bc10dafd188fca4ff57` |

## Explicit omissions

- `01_sales_performance.sql`
- `02_data_quality_investigations.sql`
- `03_delivery_performance.sql`
- `04_customer_analysis.sql`
- `05_seller_performance.sql`
- `06_product_category_performance.sql`
- `07_executive_kpi_overview.sql`

These seven completed SQL scripts are not part of this documentation package and must remain untouched in the project repository. No duplicate analysis scripts are introduced.

Also omitted: Olist raw CSV files, PostgreSQL database dumps, Power BI `.pbix` (not yet built), and credentials/secrets.
