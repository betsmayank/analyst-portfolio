# Olist bulk import (Windows / PostgreSQL 18)

This batch script imports the eight Olist CSV files that are still empty. It deliberately does not import `customers` because that table already contains 99,441 rows.

## Before running

1. Confirm the CSV files are still in:
   `C:\Users\91843\Desktop\Analyst Portfolio Project\analyst-portfolio-starter\project-01-ecommerce\data\raw`
2. Confirm PostgreSQL 18 is running.
3. Confirm `olist_analytics` exists and the eight target `raw` tables are empty, as in the latest validation screenshot.
4. Extract `03_import_remaining.psql` into:
   `analyst-portfolio-starter\project-01-ecommerce\sql\`

## Run from PowerShell

Open a normal (non-Administrator) PowerShell window and run:

```powershell
$psql = "C:\Program Files\PostgreSQL\18\bin\psql.exe"
$project = "$HOME\Desktop\Analyst Portfolio Project\analyst-portfolio-starter"
$sql = Join-Path $project "project-01-ecommerce\sql\03_import_remaining.psql"

if (-not (Test-Path $psql)) { throw "psql.exe not found at $psql. Check your PostgreSQL installation folder." }
if (-not (Test-Path $sql)) { throw "Import script not found at $sql. Check where you extracted it." }

& $psql -h localhost -p 5432 -U postgres -d olist_analytics -W -v ON_ERROR_STOP=1 --single-transaction -f $sql

if ($LASTEXITCODE -ne 0) { throw "Import failed. The single transaction should have rolled back. Send the error output before retrying." }
```

Enter your PostgreSQL `postgres` password when prompted. Do not put your password in this script or share it.

## Safety and re-runs

The script truncates the eight target tables before reloading them. It does not touch `raw.customers`. The PowerShell command uses `--single-transaction`, so a failure should roll back the batch rather than leave a partial set of imports. Only run this against the portfolio database after confirming those eight tables are empty or that you intend to replace their contents.

## Expected reference counts

Counts can vary slightly by dataset release, but the commonly distributed Olist dataset has approximately:

- customers: 99,441 (already imported)
- geolocation: 1,000,163
- order_items: 112,650
- order_payments: 103,886
- order_reviews: 99,224
- orders: 99,441
- products: 32,951
- sellers: 3,095
- product category translations: 71

The script prints actual row counts at the end. Use those actual results for the project, not the expected figures above.
