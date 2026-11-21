# Data Analyst & Business Analyst Portfolio

**Owner:** Mayank Mishra  
**Target roles:** Data Analyst | Business Analyst  
**Target markets:** India | Europe  
**Portfolio theme:** E-commerce & Digital Business Analytics

This repository contains three reproducible portfolio projects. Public datasets and synthetic data are clearly labelled. No employer or client affiliation is implied.

## Projects

| Project | Business question | Tools | Status |
|---|---|---|---|
| [01. E-commerce Business Performance](project-01-ecommerce/README.md) | What drives marketplace sales, repeat purchasing, seller/category performance and delivery experience? | PostgreSQL, SQL, Power BI, DAX | **Seven SQL analyses complete; Power BI build next** |
| [02. Salesforce CRM Pipeline](project-02-salesforce-crm/README.md) | Where does the sales pipeline lose momentum, and what revenue is forecast? | Salesforce, Tableau Public | Planned |
| [03. GA4 Conversion Funnel](project-03-ga4-funnel/README.md) | Where do online shopping sessions drop out before purchase? | GA4 sample export, BigQuery SQL, Looker Studio | Planned |

## Repository structure

- `docs/`: portfolio requirements, KPI definitions, business process documentation and project roadmap.
- `project-01-ecommerce/`: Olist data analysis, SQL, Power BI and findings.
  - `docs/analysis_log.md`: working analysis history and completed Phase 3 addendum.
  - `docs/data_quality_log.md`: original quality investigations and expanded validation results.
  - `docs/data_dictionary.md`: source/staging table grains, fields and relationships.
  - `docs/methodology.md`: original workflow decisions and completed analytical-method addendum.
- `project-02-salesforce-crm/`: synthetic CRM data, Salesforce setup and Tableau analysis.
- `project-03-ga4-funnel/`: GA4 BigQuery SQL and funnel analysis.
- `website/`: final GitHub Pages portfolio website.

## Data and reproducibility policy

- Olist is real, anonymised Brazilian marketplace data from 2016–2018. The dataset is licensed CC BY-NC-SA 4.0. Attribution and licence terms are included in the Project 01 documentation. Raw source files are not committed to this repository.
- The CRM dataset will be generated for this portfolio and is synthetic. It does not represent a real company or real customers.
- The GA4 BigQuery sample is Google's obfuscated public sample dataset. Its limitations will be disclosed.
- No private, confidential, medical, or personal customer data will be published.
- Findings are based on completed SQL outputs and supplied visual summaries. Payment-method shares in Project 01 are reported as shares of total recorded payment value, not shares of orders.
- No results or business impact will be invented.

## Current project status

Project 01 has completed database preparation, data-quality work and seven SQL analysis files. The next step is Power BI semantic modelling, DAX measure reconciliation, dashboard development and publication. See [Project 01 roadmap](docs/project_01_roadmap.md) and [Project 01 README](project-01-ecommerce/README.md).
