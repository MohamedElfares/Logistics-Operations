# Logistics Operations Database

A relational database project that migrates a synthetic logistics dataset into MySQL and analyzes it through structured views covering fleet performance, driver productivity, fuel efficiency, customer revenue, and safety risk.

---

## Dataset

Rodriguez, Yogape. (2025). *Synthetic Logistics Operations Database (2022–2024).* Kaggle.
https://www.kaggle.com/datasets/yogape/logistics-operations-database

The dataset covers three years of simulated freight operations across twelve domain areas. Raw CSV files were imported into a normalized relational schema to enable structured querying and analysis.

---

## Project Purpose

The primary goal of this project is to take a flat, multi-file dataset and migrate it into a properly structured relational database, then use that structure to answer meaningful operational questions through SQL views and stored procedures.

The migration process involved designing a normalized schema, enforcing referential integrity through foreign keys, automating data formatting through triggers, and creating analytical views that surface insights directly from the database layer — without requiring any external reporting tool.

---

## Repository Structure

```
.
├── 01_connect.sql          # Initialize schema and enable local infile
├── 02_schema.sql           # Table definitions, triggers, procedures, functions
├── 03_optimization.sql     # Analytical views and performance indexes
├── 04_load_data.sql        # Load CSV files into tables
├── run_pipeline.py         # Python automation script (runs all four files in sequence)
├── datasets/               # Source CSV files (not included in repo)
└── README.md
```

---

## How to Run

### Prerequisites

- MySQL 8.0 or later
- Python 3.10 or later with `mysql-connector-python` installed
- Source CSV files placed in the path referenced in `04_load_data.sql`

### Option 1 — Python Automation (recommended)

Edit the `CONFIG` block in `run_pipeline.py` to set your MySQL credentials and dataset path, then run:

```bash
pip install mysql-connector-python
python run_pipeline.py
```

The script executes all four SQL files in order, commits each stage, and rolls back automatically on any error.

### Option 2 — Manual Execution

Run each file individually from the MySQL command line, in order:

```bash
mysql -u root -p --local-infile=1 < connect.sql
mysql -u root -p --local-infile=1 logistics < schema.sql
mysql -u root -p --local-infile=1 logistics < optimization.sql
mysql -u root -p --local-infile=1 logistics < load_data.sql
```

---

## Schema Design

![ER Diagram](diagram.png)

The schema follows a hub-and-spoke architecture centered on the `trips` table, which links every driver, truck, trailer, and load into a single operational record.

```
customers --> loads --> trips <-- drivers
                            <-- trucks
                            <-- trailers
```

Supporting tables — `delivery_events`, `fuel_purchases`, `safety_incidents`, and `maintenance_records` — all reference trips or trucks as their primary context.

### Tables

| Table | Description |
|---|---|
| `customers` | Client accounts, contract types, and revenue potential |
| `drivers` | Driver workforce, licensing, and employment status |
| `facilities` | Warehouses, terminals, and distribution centers |
| `routes` | Standard corridors with distance, rate, and transit time |
| `loads` | Individual shipments with weight, revenue, and booking type |
| `trailers` | Trailer fleet specifications and current location |
| `trucks` | Truck fleet with acquisition, fuel type, and status |
| `trips` | Core operational record linking driver, truck, trailer, and load |
| `delivery_events` | Pickup and delivery timestamps with on-time evaluation |
| `fuel_purchases` | Per-trip fuel transactions with cost auto-calculation |
| `safety_incidents` | Accidents and violations with damage and claim amounts |
| `maintenance_records` | Vehicle service history with labor, parts, and downtime |

### Data Integrity

Foreign key constraints enforce referential integrity across all related tables. ENUM types restrict controlled fields such as load type, booking type, CDL class, and maintenance category. Several skipped rows during the load stage reflect records in the source data that referenced non-existent parent IDs — these were excluded rather than force-loaded.

### Automated Formatting

All INSERT (and relevant UPDATE) operations pass through triggers that apply the `Capitalize()` function to free-text fields and convert code fields such as state abbreviations and CDL class to uppercase. This ensures consistent formatting across the dataset regardless of how values arrived in the source files.

The `new_trip` trigger also auto-calculates `average_mpg` from actual distance and fuel consumed. The `new_event` trigger derives `on_time_flag` by comparing actual vs. scheduled datetime. The `new_fuel_purchases` trigger calculates `total_cost` as gallons × price_per_gallon.

---

## Analytical Views

Eight views were created in `03_optimization.sql` to make the most common analytical queries reusable and readable.

### Customer Analysis

**`vw_customer_performance`** aggregates total loads, total revenue, and average revenue per load for every customer. This view makes it straightforward to rank customers by profitability or identify accounts with low load volume relative to their revenue potential.

**`vw_customer_loads`** provides load-level detail per customer including freight type, weight, revenue, and combined surcharge amounts. It supports billing review and detailed revenue breakdown by shipment.

### Driver Analysis

**`vw_driver_performance`** tracks total loads, total miles driven, and average MPG per driver per year. Comparing across years reveals whether productivity and fuel efficiency are improving or declining at the individual level.

**`vw_delivery_performance`** measures on-time delivery rate per driver per year. It counts total stops, on-time stops, and computes the on-time percentage as a KPI. Drivers with consistently low on-time rates are immediately visible without any additional calculation.

**`vw_driver_loads`** joins trip, truck, trailer, and load data into a single row per trip. It is primarily useful for auditing — confirming which equipment was assigned to which driver for a given load.

### Fleet and Fuel Analysis

**`vw_fuel_efficiency`** summarizes annual fuel consumption and cost per truck, including average price per gallon and tank capacity. Tracking total fuel cost against total gallons consumed over time highlights trucks with deteriorating efficiency or abnormal purchase patterns.

**`vw_load_trip`** links each load to its route, showing origin, destination, and standard route distance. This view supports analysis of whether actual trip distances align with expected route distances and which corridors carry the most freight volume.

### Safety and Risk Analysis

**`vw_truck_maintenance_cost`** groups safety incidents by driver and year, reporting incident count, average vehicle damage cost, and concatenated incident descriptions. It serves as a risk register at the driver level and supports decisions about training, reassignment, or insurance review.

---

## Stored Procedures

Three stored procedures are included for targeted operational lookups:

`sp_customer_revenue(cust_id)` returns total revenue for a given customer ID directly from the loads table.

`sp_truck_maintenance(truck)` returns total service count and cumulative maintenance cost for a given truck.

`sp_update_trip_mpg(trip)` recalculates and updates `average_mpg` for a specific trip using its actual distance and fuel values. This is useful when source data arrives with stale or missing MPG values.

---

## Performance Indexes

Indexes were added on the most frequently filtered or joined columns: customer name and type, driver first and last name (individually and combined), facility name and type, trailer number and type, and truck unit number, make, and tank capacity. These indexes improve query performance as data volume grows, particularly for views that join across multiple large tables.

---

## Limitations

The schema does not support real-time GPS or telematics data. Route optimization and scheduling are handled externally — this database tracks what happened, not what should happen. Historical versioning is not implemented; updates to driver status or truck assignments overwrite previous states rather than preserving a record of changes. Geographic modeling uses city and state strings rather than geospatial data types, which limits spatial querying.

---

## Potential Extensions

- Add a `driver_scores` table to persist computed KPIs (on-time rate, MPG, incident count) as a historical record rather than recalculating from views on every query
- Implement soft deletes and history tables for drivers and assets to support audit trails
- Replace city/state strings with a `locations` table and geospatial columns for distance and mapping queries
- Connect the schema to a BI tool such as Metabase or Apache Superset for dashboard-level reporting

