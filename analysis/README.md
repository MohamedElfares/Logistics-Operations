# Section 2 — SQL Analysis and Query Development

This section contains a structured set of SQL queries written against the logistics database built in Section 1. The queries are organized by concept and increase in complexity within each category. Each file targets a real business question from the logistics domain and is grounded in the actual schema and dataset.

---

## Prerequisites

The database must be fully set up and populated before running any queries in this section. See [setup/README.md](../setup/README.md) for instructions.

---

## Structure

```
analysis/
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

## Joins

Multi-table JOIN queries that combine data across the schema to answer operational questions. Each file demonstrates a different JOIN pattern or use case.

| File | Description |
|---|---|
| `trip_overview.sql` | Five-table JOIN returning driver, truck, trailer, and customer details for every trip |
| `loads_without_trips.sql` | LEFT JOIN with NULL filter to identify loads that were booked but never dispatched |
| `delivery_events_location_analysis.sql` | Investigates the relationship between facility city and event location city — see Findings below |
| `drivers_no_safety_incidents.sql` | Drivers with no safety incidents who have completed at least one trip |
| `fuel_purchases_trip_details.sql` | One row per fuel purchase with driver, truck, and dispatch context |
| `fuel_purchases_trip_summary.sql` | Fuel purchases aggregated per trip — average gallons, average price, and total cost |

### Key Concepts Demonstrated

**LEFT JOIN with NULL filtering** is used in `loads_without_trips.sql` and `drivers_no_safety_incidents.sql` to find records with no match in a related table. The IS NULL filter must be applied to a column from the right-side table to correctly isolate unmatched rows without converting the LEFT JOIN into an INNER JOIN.

**Indirect relationships** are demonstrated in `trip_overview.sql`, which reaches the customers table through loads since customers have no direct foreign key to trips. This is a common pattern in normalized schemas where relationships span multiple tables.

**Driving table selection** is a deliberate choice in `fuel_purchases_trip_details.sql`, which starts from fuel_purchases rather than trips to ensure every purchase appears in the result, including those with missing trip references.

**HAVING vs WHERE for aggregated filters** is demonstrated in `drivers_no_safety_incidents.sql`, which uses HAVING to filter on COUNT(trips) after grouping since WHERE cannot reference aggregate functions.

---

## CTEs

Common Table Expression queries that pre-aggregate or pre-process data before the main query runs. Each file demonstrates a different CTE pattern.

| File | Description |
|---|---|
| `customers_above_avg_revenue.sql` | Two CTEs — annual revenue per customer, overall average — compared via CROSS JOIN |
| `active_drivers_ranked_by_miles.sql` | CTE pre-aggregates miles per driver, joined back to the drivers table and ranked with RANK() |
| `truck_operating_costs_by_year.sql` | Two CTEs — annual fuel cost and maintenance cost per truck — joined side by side for comparison |
| `monthly_shipment_coverage.sql` | Recursive CTE generates a dynamic monthly date series, LEFT JOINed to loads to count shipments per month |
| `drivers_route_distance_variance.sql` | CTE flags each trip by distance variance category, outer query counts categories per driver |

### Key Concepts Demonstrated

**Multi-CTE patterns** are used in `customers_above_avg_revenue.sql` and `truck_operating_costs_by_year.sql`, where two CTEs are defined in sequence and the second references the first. This keeps complex aggregations modular and readable.

**CROSS JOIN for benchmark attachment** is applied in `customers_above_avg_revenue.sql`, where a single-row CTE holding the overall revenue average is attached to every customer row. Since the right side is always one row, no duplication occurs and the WHERE clause can compare each customer directly against the benchmark.

**Recursive CTEs** are used in `monthly_shipment_coverage.sql` to generate a complete month series between the minimum and maximum load dates. Both endpoints are derived dynamically from the data, making the query self-adapting to any date range without hardcoded values.

**NULL year handling** is addressed in `truck_operating_costs_by_year.sql`, where trucks with no fuel purchases produce a NULL year group from YEAR(NULL). This is filtered in the outer query with WHERE year IS NOT NULL rather than restructuring the CTEs.

**Threshold calibration** is documented in `drivers_route_distance_variance.sql`, where the initial 10% over-route threshold returned no results. A ratio analysis revealed the dataset constrains actual distance to within ±8% of the typical route distance, requiring the threshold to be adjusted. See Findings below.

---

## Window Functions

Window functions extend the analytical capability of the queries by computing values across related rows without collapsing the result through aggregation. The files are organized into three subcategories: ranking, fetching, and aggregate.

### Ranking

Ranking window functions assign a positional value to each row within a defined partition.

| File | Description |
|---|---|
| `drivers_ranked_by_loads_per_year.sql` | Ranks drivers by total loads completed within each calendar year using RANK() — ties receive the same rank and the next rank is skipped |
| `customers_ranked_by_revenue_per_type.sql` | Ranks customers by total revenue within each customer type using DENSE_RANK() — consecutive ranking is preserved on ties |
| `drivers_trip_history.sql` | Assigns a unique sequential trip number to each driver's trips ordered by dispatch date using ROW_NUMBER() |
| `drivers_mpg_quartiles.sql` | Buckets drivers into four fuel efficiency performance tiers using NTILE(4), with a readable quartile label derived from a CASE expression |
| `trucks_top3_fuel_cost_per_year.sql` | Identifies the top 3 highest fuel-spending trucks per year using RANK() inside a CTE, enabling the result to be filtered on the computed rank in the outer query |

### Key Concepts Demonstrated

**RANK() vs DENSE_RANK() vs ROW_NUMBER()** serve different purposes depending on how ties should be handled. RANK() skips ranks after a tie, DENSE_RANK() preserves consecutive ranks, and ROW_NUMBER() always assigns a unique number regardless of ties. The choice between them affects the analytical meaning of the result.

**Filtering on window function results** requires a CTE or subquery. Window functions are evaluated after WHERE, making it impossible to filter on a computed rank in the same query where it is defined. `trucks_top3_fuel_cost_per_year.sql` demonstrates this pattern explicitly.

**NTILE() for segmentation** divides a population into equal-sized buckets based on a metric. In `drivers_mpg_quartiles.sql`, this produces a performance tier for every driver without requiring manual threshold definition.

### Fetching

Fetching window functions retrieve values from other rows within the same partition — either preceding or following the current row.

| File | Description |
|---|---|
| `drivers_trip_distance_lag.sql` | Uses LAG() to compare each driver's current trip distance against their previous trip — surfaces sudden route length deviations |
| `delivery_events_stop_gap_hours.sql` | Uses LEAD() to calculate the planned gap in hours between consecutive delivery stops on the same load |
| `drivers_first_dispatch_date.sql` | Applies FIRST_VALUE() to attach each driver's earliest dispatch date to every row in their trip history — skill development exercise |
| `drivers_most_recent_trip_distance.sql` | Applies LAST_VALUE() with an extended frame clause to attach each driver's most recent trip distance to every row — skill development exercise |
| `trucks_3rd_most_expensive_fuel_purchase.sql` | Applies NTH_VALUE() with an extended frame clause to retrieve the third most expensive fuel purchase per truck — skill development exercise |

### Key Concepts Demonstrated

**LAG() and LEAD()** are the primary fetching functions with direct business relevance in this dataset. LAG() enables row-to-row comparison within a chronological sequence, making it possible to detect sudden changes that aggregation would obscure. LEAD() converts a sequence of timestamps into a measurable interval between events.

**FIRST_VALUE(), LAST_VALUE(), and NTH_VALUE()** are included as skill-building exercises to develop familiarity with positional window functions. They demonstrate how a single reference value can be carried across all rows in a partition without aggregation.

**The default frame clause problem** affects LAST_VALUE() and NTH_VALUE() specifically. The default frame RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW causes both functions to behave unexpectedly — LAST_VALUE() returns the current row's own value, and NTH_VALUE() returns NULL on rows before the nth position. Extending the frame to ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING resolves this in both cases.

### Aggregate

Aggregate window functions apply standard aggregation — SUM, AVG, COUNT — across a defined window of rows while preserving individual row detail.

| File | Description |
|---|---|
| `loads_running_revenue.sql` | Computes a global running total of revenue across all loads ordered by load date |
| `drivers_rolling_avg_mpg.sql` | Computes a 3-trip backward-looking rolling average of MPG per driver to smooth individual trip variation |
| `drivers_cumulative_claim_amount.sql` | Tracks cumulative insurance claim amount per driver ordered by incident date — surfaces total financial exposure at each point in a driver's safety history |
| `customers_revenue_pct_by_type.sql` | Shows each customer's revenue as a percentage of total revenue within their customer type using SUM() as a window function |
| `trucks_cumulative_maintenance_cost.sql` | Computes running total of maintenance cost per truck with a threshold flag identifying when cumulative spend crosses $10,000 |

### Key Concepts Demonstrated

**Running totals** accumulate a value chronologically, transforming point-in-time figures into a continuous growth curve. `loads_running_revenue.sql` and `trucks_cumulative_maintenance_cost.sql` both use this pattern — the former for revenue growth analysis, the latter for cost threshold monitoring.

**Rolling averages** smooth out short-term variation to surface underlying trends. The 3-trip rolling average in `drivers_rolling_avg_mpg.sql` uses ROWS BETWEEN 2 PRECEDING AND CURRENT ROW, a backward-looking frame that averages each trip with the two that preceded it.

**Revenue distribution within segments** is addressed in `customers_revenue_pct_by_type.sql`, where SUM() is partitioned by customer type to compute a denominator for each segment independently. This avoids cross-segment comparison and surfaces account concentration within each contract tier.

**The frame clause distinction** between running totals and fetching functions is worth noting. For SUM() and AVG() used as running or rolling computations, the default frame is appropriate and intentional. For LAST_VALUE() and NTH_VALUE(), the default frame must be overridden. Understanding when to accept the default and when to extend it is one of the core skills developed across these exercises.

---

## Findings

Analytical findings that emerged from querying the data — cases where results were unexpected and required investigation before the correct interpretation could be documented.

### delivery_events — location_city vs facility city

While joining `delivery_events` to `facilities` to retrieve event location data, a 96.55% mismatch was found between `facilities.city` and `delivery_events.location_city`. The initial assumption was a data quality issue in the source dataset.

Further investigation by joining through `loads` to `routes` revealed a consistent pattern: for Pickup events, `location_city` matches `routes.origin_city`, and for Delivery events it matches `routes.destination_city`. The column represents the shipment city derived from the route, not the facility's operational city. The two fields serve different analytical purposes and should not be compared directly. See `delivery_events_location_analysis.sql` for the full three-step investigation.

### drivers_route_distance_variance — threshold calibration

Applying a standard 10% over-route threshold to flag trips with excessive distance returned zero results across all drivers. A ratio analysis of actual versus typical distance produced the following:

| Metric | Value |
|---|---|
| Min ratio | 0.976 |
| Max ratio | 1.0799 |
| Avg ratio | 1.029 |

The synthetic dataset constrains actual distance to within approximately ±8% of the typical route distance, making the 10% threshold ineffective. The threshold was adjusted to 5% over and 1% under to produce a meaningful three-category classification. This is a characteristic of how the dataset was generated and does not reflect real-world operational variance.
