# Portfolio Requirements Document

## 1. Purpose

Build a public, reproducible portfolio that demonstrates entry-level Data Analyst and Business Analyst capabilities through three end-to-end business cases.

## 2. Target audience

Hiring managers, recruiters and analytics team members hiring for Data Analyst or Business Analyst roles in India and Europe.

## 3. Core requirements

1. Each project must begin with a specific business problem and stakeholder decision.
2. Each metric must have a written definition, numerator, denominator, grain and exclusions where relevant.
3. Each analysis must be reproducible from documented data sources and scripts.
4. Each dashboard must answer business questions, not merely display charts.
5. Each project must include findings, limitations and concrete recommendations.
6. Every number in a finding must come from a validated query or report output.
7. Synthetic and obfuscated data must be labelled honestly.
8. The repository must not contain credentials, private data or unnecessary raw datasets.
9. Documentation and dashboard labels must use professional English and explicit currency/date units.
10. The portfolio website must link to all three projects and their published dashboards.

## 4. Project scope

### Project 1: E-commerce Business Performance & Customer Experience

Analyse the Olist Brazilian marketplace dataset to understand product GMV, order trends, repeat purchasing, delivery performance and review outcomes. Use PostgreSQL for data preparation and SQL analysis, and Power BI for the interactive dashboard.

### Project 2: Salesforce CRM & Sales Pipeline

Use a generated synthetic B2B CRM dataset to configure Salesforce, track leads and opportunities, build native Salesforce reports, and create a deeper Tableau Public dashboard.

### Project 3: GA4 E-commerce Conversion Funnel

Use Google's public, obfuscated GA4 ecommerce BigQuery sample to analyse session acquisition and the shopping journey from product view through purchase. Use BigQuery SQL and Looker Studio for visualisation.

## 5. Non-functional requirements

- Reproducibility: include setup steps, source links, SQL and field definitions.
- Accuracy: reconcile important dashboard totals to SQL outputs.
- Transparency: disclose data limitations and assumptions.
- Accessibility: use descriptive titles, readable labels and consistent formatting.
- Privacy: do not publish credentials, personal records or private business data.
- Portability: use free or widely available tools wherever practical.

## 6. Out of scope

- Claiming commercial impact for simulated projects.
- Presenting synthetic CRM records as real customers or sales.
- Treating historical sample data as current market evidence.
- Building predictive machine-learning models before the core descriptive analysis is validated.

## 7. Acceptance criteria

A project is complete only when its data source, business question, methodology, KPI definitions, analysis, dashboard, findings, limitations, README and reproduction instructions are present and checked. A dashboard screenshot alone does not qualify.
