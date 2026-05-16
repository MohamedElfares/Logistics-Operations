# Logistics Operations Database

An end-to-end SQL project built on a synthetic logistics dataset covering three years of freight operations (2022–2024). The project is divided into two sections that build on each other sequentially — the first covers database design and migration, the second covers structured SQL analysis and query development.

---

## Dataset

Rodriguez, Yogape. (2025). *Synthetic Logistics Operations Database (2022–2024).* Kaggle.
https://www.kaggle.com/datasets/yogape/logistics-operations-database

The dataset covers twelve operational domains — customers, drivers, trucks, trailers, loads, routes, trips, delivery events, fuel purchases, safety incidents, maintenance records, and facilities — spanning approximately 85,000 trip records across three years.

---

## Project Structure

```
.
├── README.md                           # This file — project overview and navigation
│
├── setup/                              # Section 1: Database Design and Migration
│   ├── README.md
│   ├── 01_connect.sql
│   ├── 02_schema.sql
│   ├── 03_optimization.sql
│   ├── 04_load_data.sql
│   ├── run_pipeline.py
│   └── datasets/                       # Source CSV files (not included in repo)
│
└── analysis/                           # Section 2: SQL Analysis and Query Development
    ├── README.md
    ├── joins/
    │   ├── trip_overview.sql
    │   ├── loads_without_trips.sql
    │   ├── delivery_events_location_analysis.sql
    │   ├── drivers_no_safety_incidents.sql
    │   ├── fuel_purchases_trip_details.sql
    │   └── fuel_purchases_trip_summary.sql
    ├── ctes/
    │   ├── customers_above_avg_revenue.sql
    │   ├── active_drivers_ranked_by_miles.sql
    │   ├── truck_operating_costs_by_year.sql
    │   ├── monthly_shipment_coverage.sql
    │   └── drivers_route_distance_variance.sql
    ├── window_functions/
    │   ├── ranking/
    │   │   ├── drivers_ranked_by_loads_per_year.sql
    │   │   ├── customers_ranked_by_revenue_per_type.sql
    │   │   ├── drivers_trip_history.sql
    │   │   ├── drivers_mpg_quartiles.sql
    │   │   └── trucks_top3_fuel_cost_per_year.sql
    │   ├── fetching/
    │   │   ├── drivers_trip_distance_lag.sql
    │   │   ├── delivery_events_stop_gap_hours.sql
    │   │   ├── drivers_first_dispatch_date.sql
    │   │   ├── drivers_most_recent_trip_distance.sql
    │   │   └── trucks_3rd_most_expensive_fuel_purchase.sql
    │   └── aggregate/
    │       ├── loads_running_revenue.sql
    │       ├── drivers_rolling_avg_mpg.sql
    │       ├── drivers_cumulative_claim_amount.sql
    │       ├── customers_revenue_pct_by_type.sql
    │       └── trucks_cumulative_maintenance_cost.sql
    └── findings/
        └── delivery_events_location_analysis.md
```

---

## Section 1 — Database Design and Migration

The first section covers the full process of taking twelve raw CSV files and migrating them into a structured, normalized MySQL database.

This includes schema design with foreign key constraints and ENUM types, data formatting automation through triggers, analytical views and stored procedures, performance indexing, and a Python automation script that runs the full setup pipeline in sequence with rollback on failure.

See [setup/README.md](setup/README.md) for full documentation.

---

## Section 2 — SQL Analysis and Query Development

The second section builds on the database from Section 1 with a structured set of SQL exercises and exploratory analysis queries. Each query is written against the real schema and dataset, grounded in actual business questions a logistics operation would ask.

The analysis is organized by SQL concept and expands progressively:

- **Joins** — multi-table joins across up to five related tables, LEFT JOIN with NULL filtering, indirect relationships, and driving table selection
- **CTEs** — pre-aggregation patterns, multi-CTE comparisons, CROSS JOIN benchmarking, and recursive date series generation
- **Window Functions** — ranking and segmentation with RANK(), DENSE_RANK(), ROW_NUMBER(), and NTILE(); row-to-row comparison with LAG() and LEAD(); running totals, rolling averages, cumulative tracking, and revenue distribution with aggregate window functions

A key outcome of this section is a set of documented data findings that emerged during analysis — cases where querying the data revealed something unexpected about how the dataset was structured or generated, requiring investigation before the correct interpretation could be established.

See [analysis/README.md](analysis/README.md) for full documentation.

---

## How to Run

Section 1 must be completed before Section 2. The database must be set up and populated before any analysis queries can be executed.

Refer to [setup/README.md](setup/README.md) for setup instructions.

---

## Tools

MySQL 8.0, Python 3.10, mysql-connector-python
