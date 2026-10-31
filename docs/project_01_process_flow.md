# Business Analysis Process Flow: Project 1

```mermaid
flowchart TD
    A[Stakeholder asks why sales and customer experience vary] --> B[Define decisions and scope]
    B --> C[Identify Olist source tables and business keys]
    C --> D[Import raw CSV files into PostgreSQL]
    D --> E[Profile row counts, nulls, duplicates and joins]
    E --> F{Data quality acceptable?}
    F -- No --> G[Document issue and apply controlled cleaning rule]
    G --> E
    F -- Yes --> H[Create analysis-ready SQL views and queries]
    H --> I[Calculate and reconcile KPIs]
    I --> J[Build Power BI model and report]
    J --> K[Validate dashboard totals against SQL]
    K --> L{Do results answer stakeholder questions?}
    L -- No --> H
    L -- Yes --> M[Write findings, limitations and recommendations]
    M --> N[Publish reproducible project to GitHub]
```

## Business Analyst explanation

The process separates the business need from the solution. Requirements are agreed before dashboard design; data quality is checked before metrics are calculated; and dashboard figures are reconciled to SQL before recommendations are presented. This reduces the risk of building a polished report around incorrect numbers.
