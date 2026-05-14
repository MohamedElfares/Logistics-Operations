# Section 2 — SQL Analysis and Query Development

This section contains a structured set of SQL queries written against the logistics database built in Section 1. The queries are organized by concept and increase in complexity within each category. Each file targets a real business question from the logistics domain and is grounded in the actual schema and dataset.

The section is designed to grow — window function tasks are planned as the next phase and will be added to this section as they are completed.

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
├── window_functions/           # In progress
│   ├── ranking/
│   ├── fetching/
│   └── aggregate/
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

**LEFT JOIN with NULL filtering** — used in `loads_without_trips.sql` and `drivers_no_safety_incidents.sql` to find records with no match in a related table. The IS NULL filter must be applied to a column from the right-side table to correctly isolate unmatched rows without converting the LEFT JOIN into an INNER JOIN.

**Indirect relationships** — `trip_overview.sql` reaches the customers table through loads, since customers have no direct foreign key to trips. This is a common pattern when the schema is normalized and relationships are indirect.

**Driving table selection** — `fuel_purchases_trip_details.sql` starts from fuel_purchases rather than trips to ensure every purchase appears in the result, including those with missing trip references.

**HAVING vs WHERE for aggregated filters** — `drivers_no_safety_incidents.sql` uses HAVING to filter on COUNT(trips) after grouping, since WHERE cannot reference aggregate functions.

---

## CTEs

Common Table Expression queries that pre-aggregate or pre-process data before the main query runs. Each file demonstrates a different CTE pattern.

| File | Description |
|---|---|
| `customers_above_avg_revenue.sql` | Two CTEs — annual revenue per customer, overall average — filtered with CROSS JOIN comparison |
| `active_drivers_ranked_by_miles.sql` | CTE pre-aggregates miles per driver, joined back to drivers table and ranked with RANK() |
| `truck_operating_costs_by_year.sql` | Two CTEs — annual fuel cost and maintenance cost per truck — joined side by side for comparison |
| `monthly_shipment_coverage.sql` | Recursive CTE generates a dynamic monthly date series, LEFT JOINed to loads to count shipments per month |
| `drivers_route_distance_variance.sql` | CTE flags each trip by distance variance category, outer query counts categories per driver |

### Key Concepts Demonstrated

**Multi-CTE patterns** — `customers_above_avg_revenue.sql` and `truck_operating_costs_by_year.sql` use two CTEs in sequence, where the second CTE references the first. This keeps complex aggregations modular and readable.

**CROSS JOIN for benchmark attachment** — in `customers_above_avg_revenue.sql`, a single-row CTE holding the overall average is attached to every customer row via CROSS JOIN. Since the right side is always one row, no duplication occurs and the WHERE clause can compare each row against the benchmark directly.

**Recursive CTEs** — `monthly_shipment_coverage.sql` uses a recursive CTE to generate a complete month series between MIN and MAX load dates. Both endpoints are derived dynamically from the data, making the query self-adapting to any date range.

**NULL year handling** — in `truck_operating_costs_by_year.sql`, trucks with no fuel purchases produce a NULL year group from YEAR(NULL). This is filtered in the outer query with WHERE year IS NOT NULL rather than restructuring the CTEs.

**Threshold calibration** — in `drivers_route_distance_variance.sql`, the initial 10% over-route threshold returned no results. A ratio analysis revealed the dataset constrains actual distance to within ±8% of typical distance, requiring the threshold to be adjusted to 5%. See Findings below.

---

## Window Functions

*(In progress — will cover ranking, fetching, and aggregate window functions)*

### Planned Tasks

**Ranking**
- Rank drivers by total loads per year using `RANK()`
- Rank customers by revenue within customer type using `DENSE_RANK()`
- Assign sequential trip numbers per driver using `ROW_NUMBER()`
- Bucket drivers into MPG performance quartiles using `NTILE(4)`
- Find top 3 trucks by annual fuel cost using `RANK()` with CTE filtering

**Fetching**
- Show previous trip distance per driver using `LAG()`
- Calculate gap between consecutive delivery stops using `LEAD()`
- Show each driver's first dispatch date on every trip row using `FIRST_VALUE()`
- Show each driver's most recent trip distance using `LAST_VALUE()` with frame clause
- Retrieve the third most expensive fuel purchase per truck using `NTH_VALUE()`

**Aggregate**
- Running total of revenue by load date using `SUM()` as a window function
- 3-trip rolling average MPG per driver using `AVG()` with `ROWS BETWEEN` frame
- Cumulative claim amount per driver ordered by incident date
- Each customer's revenue as a percentage of their customer type total using `SUM()`
- Running total of maintenance cost per truck to identify cost threshold crossings

---

## Findings

Analytical findings that emerged from querying the data — cases where results were unexpected and required investigation.

### delivery_events — location_city vs facility city

While joining `delivery_events` to `facilities` to retrieve event location data, a 96.55% mismatch was found between `facilities.city` and `delivery_events.location_city`. The initial assumption was a data quality issue in the Kaggle dataset.

Further investigation by joining through `loads` to `routes` revealed a clear pattern:

- For **Pickup** events → `location_city` matches `routes.origin_city`
- For **Delivery** events → `location_city` matches `routes.destination_city`

`location_city` in `delivery_events` represents the shipment city derived from the route, not the facility's city. The two columns serve different analytical purposes and should not be compared directly. See `delivery_events_location_analysis.sql` for the full three-step investigation.

### drivers_route_distance_variance — threshold calibration

A 10% over-route threshold returned zero flagged trips across all drivers. A ratio analysis of actual vs typical distance revealed:

| Metric | Value |
|---|---|
| Min ratio | 0.976 |
| Max ratio | 1.0799 |
| Avg ratio | 1.029 |

The synthetic dataset constrains actual distance to within ±8% of the typical route distance. The standard 10% outlier threshold is therefore ineffective on this data. The threshold was adjusted to 5% over and 1% under to produce a meaningful three-category classification. This is a dataset generation characteristic, not a real-world operational pattern.
