# Section 3 — Fleet Performance Dashboard

This section takes the MySQL database built in Section 1 and the analytical findings documented in Section 2 and turns them into an interactive Power BI report. The dashboard covers five operational domains across three years of logistics data: fleet utilization, route profitability, delivery performance, fuel efficiency, and safety and maintenance.

---

## Prerequisites

The database from Section 1 must be fully set up and populated before the dashboard can connect or refresh. See [setup/README.md](../setup/README.md) for instructions.

The SQL analysis in Section 2 is not a technical prerequisite, but the data quality findings documented there — particularly around orphaned loads, route distance variance, and the delivery events location mismatch — directly inform several of the design decisions made in the data model.

---

## Structure

```
dashboard/
├── README.md                               # This file
├── Fleet Performance Dashboard.pbix        # Power BI report
├── FleetTheme.json                         # Custom color and font theme
└── docs/
    ├── er_diagram.html                     # Interactive ER diagram with PNG export
    ├── er_diagram_2x_HD.png                # ER diagram at 3538×3146px (300 DPI)
    ├── fleet_pbi.html                      # Static HTML preview of all seven pages
    ├── powerbi_implementation_guide.html   # Full design and implementation reference
    └── fleet_dashboard_compact.md          # Measure inventory, DAX patterns, session notes
```

---

## Data Model

### Connection

The report connects to the MySQL logistics database via MySQL Connector/ODBC 8.0 (64-bit) using Import mode. DirectQuery was considered and rejected for two reasons: DAX time intelligence functions (`TOTALYTD()`, `SAMEPERIODLASTYEAR()`, `DATESINPERIOD()`) require a proper Date table that is not supported in DirectQuery against MySQL, and the dataset at approximately 150MB fits comfortably in memory, making import the faster and more capable option.

A full refresh is required to pick up new data from the source.

### Tables

All twelve tables from the source schema are imported into the model:

| Table | Role in model |
|---|---|
| `trips` | Central fact table linking driver, truck, trailer, and load into one operational record |
| `loads` | Load-level revenue and shipment data, connected to trips via `load_id` |
| `customers` | Client accounts and contract types, reached through loads |
| `drivers` | Driver workforce data, directly related to trips |
| `trucks` | Fleet specifications including manufacturer, model year, and fuel type |
| `trailers` | Trailer assignments and type specifications |
| `routes` | Standard freight corridors with origin, destination, and distance |
| `facilities` | Warehouses and distribution centers |
| `delivery_events` | Pickup and delivery timestamps per load, with on-time evaluation |
| `fuel_purchases` | Per-trip fuel transactions with gallons, price, and state |
| `safety_incidents` | Accidents and violations per driver with claim and damage amounts |
| `maintenance_records` | Vehicle service history per truck with cost and downtime |

A `Date` table is generated in DAX using `ADDCOLUMNS(CALENDAR(...))` with start and end dates derived dynamically from `MIN` and `MAX` of `Trips[dispatch_date]`. Auto date/time is disabled across the entire model.

### Relationships

The relationship structure mirrors the hub-and-spoke schema from Section 1, with `trips` as the central fact table.

One active date relationship is defined: `Date → Trips[dispatch_date]`. All other date-to-fact relationships — to `fuel_purchases`, `maintenance_records`, and `safety_incidents` — are inactive by default and activated selectively in specific measures using `USERELATIONSHIP()`. This keeps the default time intelligence behavior consistent across all page-level slicers while allowing individual measures to override it when they need to filter by a different event date, such as maintenance service date rather than trip dispatch date.

Several dimension-to-fact relationships are also inactive:

| Inactive relationship | Activation context |
|---|---|
| `Trucks → FuelPurchases` | Fuel analysis measures requiring truck-level fuel aggregation |
| `Trucks → MaintenanceRecords` | Maintenance cost measures |
| `Trucks → SafetyIncidents` | Safety analysis measures |
| `Drivers → FuelPurchases` | Driver-level fuel efficiency analysis |
| `Drivers → SafetyIncidents` | Driver safety history measures |
| `Trips → DeliveryEvents` | Delivery performance measures |

The `Loads ↔ Trips` relationship uses bidirectional cross-filtering with 1:1 cardinality. This reflects the operational reality that each load maps to exactly one trip, and allows filter context to propagate in either direction between the two tables.

---

## Measure Architecture

All 130 measures are stored in a dedicated table named `_Measures`. Separating measures from source tables keeps the report field list clean and makes the distinction between data columns and calculated values explicit.

### Display Folders

Measures are organized into 16 display folders split between two categories: analytical measures used as building blocks across the model, and page-level measures scoped to a specific report page.

**Analytical folders**

| Folder | Count | Contents |
|---|---|---|
| `Base Counts` | 6 | Row counts and totals used as building blocks in other measures |
| `Revenue` | 5 | Total and attributed revenue, orphan gap, and per-truck average |
| `Fleet Performance` | 4 | Active trucks, active truck-days, available truck-days, and utilization rate |
| `Cost & Efficiency` | 6 | Fuel cost, maintenance cost, total operating cost, cost per mile, and allocated maintenance |
| `Route Profitability` | 2 | Route profit margins with fuel-only and fuel-plus-maintenance deductions |
| `Delivery Performance` | 3 | On-time count, late count, and on-time rate |
| `Time Intelligence` | 3 | YTD revenue, prior-year revenue, and YoY growth |
| `Visual Formatting` | 4 | Hex color strings for conditional bar chart formatting |
| `Targets & Config` | 5 | Benchmark targets, flagging thresholds, route counts, and refresh timestamp |
| `Safety & Maintenance` | 19 | Incident counts, claim amounts, maintenance cost, downtime, fault flags, and efficiency labels |
| `Fuel Insights` | 12 | MPG calculations, price per gallon, YoY fuel trends, per-truck efficiency ratings, and bar colors |

**Page-level folders**

| Folder | Count | Contents |
|---|---|---|
| `Executive Summary Page` | 10 | Header KPIs and dynamic labels for the Executive Summary page |
| `Fleet Performance Page` | 15 | Header KPIs and dynamic labels for the Fleet Performance page |
| `Route Profitability Page` | 11 | Header KPIs and dynamic labels for the Route Profitability page |
| `Delivery Performance Page` | 15 | Header KPIs and dynamic labels for the Delivery Performance page |
| `Fuel Analysis Page` | 10 | Header KPIs and dynamic labels for the Fuel Analysis page |

### Naming Conventions

Measure names follow a prefix system that communicates both function and display location:

| Prefix | Role | Behavior |
|---|---|---|
| No prefix | Base analytical measure | Slicer-responsive; used as a dependency in other measures |
| `🏷️` | Page header KPI | Always-unfiltered; uses `REMOVEFILTERS()` for a stable full-dataset reference |
| `📌` | Supporting label beneath a KPI card | Either slicer-responsive or unfiltered, depending on the card's purpose |
| `⚠️` | Alert or data quality banner | Dynamic text surfacing anomalies; uses `REMOVEFILTERS()` throughout |

The distinction between `🏷️` and base measures is deliberate. A base measure like `[Fleet Utilization Rate]` responds to every slicer and is used in charts and tables. Its header counterpart `[🏷️ Fleet Utilization Rate]` wraps it with `REMOVEFILTERS()` and appears in the page title bar as a fixed reference, giving the reader a full-period baseline to compare against the filtered chart beneath it.

---

## Dashboard Pages

The report contains seven pages.

| Page | Description |
|---|---|
| Executive Summary | Fleet-wide KPIs in a single view: attributed revenue, fleet utilization, data quality gap, YoY growth, and active truck count. A dynamic data quality alert banner at the bottom of the page lists all known data issues with live values. |
| Fleet Performance | Per-truck breakdown of revenue, cost per mile, and utilization rate using horizontal bar charts with conditional color formatting. A fleet-wide subtitle and per-truck efficiency labels are generated dynamically from measure values. |
| Route Profitability | Route-level profit margins after fuel costs and proportionally allocated maintenance, ranked by profitability. Six anomalous routes are flagged and separated from the reliable-route analysis. |
| Delivery Performance | On-time delivery rate by customer, contract type, and period. Fleet rate of 55.7% is shown against the 80% industry benchmark across Contract, Spot, and Dedicated customer segments with per-customer performance classification. |
| Safety & Maintenance | Safety incident breakdown by fault classification, injury, and preventability. Includes average equipment downtime per service event, cumulative claim amounts, and the highest-cost maintenance type derived dynamically from the data. |
| Fuel Analysis | Fleet-wide fuel spend, price per gallon by state, rolling 3-month cost trend, and MPG context. Dynamic labels surface the top two fuel-spending states and their combined share of total fleet fuel spend. |
| Findings & Insights | Narrative summary of the key analytical findings from the dataset — orphaned load revenue gap, flagged routes, fleet idle rate, and the systemic on-time delivery shortfall. |

---

## Key Design Decisions

### Orphaned Load Revenue Attribution

4,952 loads (5.8%) have no matching trip record. These loads carry $15.25M in revenue that cannot be attributed to any truck, driver, or route. All profitability and efficiency measures in the model use `[Revenue with Trip Data]` as their base rather than `[Total Revenue]`. The gap is surfaced explicitly on the Executive Summary page rather than silently excluded.

`[Revenue with Trip Data]` uses a `TREATAS()` semi-join rather than a direct filter on the `load_id` column:

```dax
CALCULATE(
    [Total Revenue],
    TREATAS(VALUES(Trips[load_id]), Loads[load_id])
)
```

A direct filter on `Loads[load_id]` would attempt to add a second filter path over an existing active relationship, creating ambiguity in the model. `TREATAS()` applies the `Trips[load_id]` values as a virtual filter on `Loads[load_id]` without touching the relationship structure.

### Header KPI Stability vs Slicer Responsiveness

Every `🏷️` header measure uses `REMOVEFILTERS()` to remain stable as a full-dataset reference regardless of active slicer state. Every base analytical measure and `Fuel Insights` measure does not use `REMOVEFILTERS()` and responds to all slicers. The two categories serve different purposes on the same page: the header provides an anchor, the visuals show the filtered view.

Where a measure that is unfiltered for header display is also needed in a slicer-responsive context, two separate measures are maintained. `[🏷️ % of revenue]` and `[📌 % of revenue]` are one example: the `🏷️` version wraps both operands in `REMOVEFILTERS()` for the title card, while the `📌` version computes the same ratio without `REMOVEFILTERS()` so the supporting label beneath it reflects the current slicer selection.

### Proportional Maintenance Allocation

The `[Allocated Maintenance]` measure distributes total fleet maintenance cost across routes by mileage share:

```dax
VAR RouteShare =
    DIVIDE(
        [Route Miles],
        CALCULATE([Total Miles Driven], REMOVEFILTERS(Routes))
    )
RETURN
    RouteShare * [Total Maintenance Cost]
```

`REMOVEFILTERS(Routes)` on the denominator fixes the total fleet mileage as a constant, ensuring each route's share is calculated against the full fleet rather than the routes currently visible in the visual filter. Without this, every route viewed in isolation would claim 100% of fleet maintenance cost.

### FILTER Wrapper for Dimension Table Predicates

Passing a measure as a direct boolean predicate inside `CALCULATE()` when the filter target is a dimension table evaluates the measure in the wrong filter context and produces incorrect results silently. All dimension-level filters in this model use an explicit `FILTER()` wrapper:

```dax
-- Correct
CALCULATE(COUNTROWS(Routes), FILTER(Routes, [Fuel Cost per Mile] > 2.00))

-- Incorrect — evaluates the measure outside the row context of Routes
CALCULATE(COUNTROWS(Routes), [Fuel Cost per Mile] > 2.00)
```

### YoY Label Pattern

The year-range label used in the YoY Growth KPI card (`[📌 YoY Growth Label]`) uses `MAX('Date'[Year])` without wrapping it in `CALCULATE()`. When a measure is evaluated in a visual axis context — for example, as a column grouping in a matrix — `CALCULATE()` can fail to inherit the visual's column filter context, causing `MAX` to see all years and return the wrong value. Without `CALCULATE()`, the function reads directly from the current row and column context, including visual axes:

```dax
VAR CurrentYear = MAX('Date'[Year])   -- not CALCULATE(MAX('Date'[Year]))
VAR PriorYear   = CurrentYear - 1
RETURN FORMAT(PriorYear, "0") & "→" & FORMAT(CurrentYear, "0")
```

### DATESINPERIOD Anchor Date

The `[Fuel Cost Rolling 3M Avg]` measure uses `DATESINPERIOD()` inside `CALCULATE()` to define a 3-month rolling window. The anchor date must be passed as an inline expression rather than stored in a variable first:

```dax
VAR RollingCost =
    CALCULATE(
        [Total Fuel Cost],
        DATESINPERIOD('Date'[Date], MAX('Date'[Date]), -3, MONTH)
    )
RETURN DIVIDE(RollingCost, 3)
```

Storing `MAX('Date'[Date])` in a `VAR` and then passing the variable to `DATESINPERIOD()` inside `CALCULATE()` causes a semantic error in Power BI Desktop. The engine cannot resolve the variable reference as a valid date anchor within that evaluation context. Inlining `MAX('Date'[Date])` directly resolves this without changing the logic.

---

## Data Quality Findings

Three data quality issues emerged during modeling. Each is surfaced in the dashboard rather than corrected silently.

### Orphaned Loads

4,952 load records have no matching trip. The MySQL import for Section 1 rejected trip rows with missing foreign key references, which severed the connection between those loads and any truck, driver, or route. The $15.25M in revenue they represent is tracked in `[Revenue Missing Trip Data]` and shown in the Executive Summary data quality alert. All profitability measures exclude this revenue from their calculations.

### Flagged Routes

Six routes show fuel cost per mile between $2.07 and $12.38 against a fleet average of $0.83. The anomaly is a characteristic of synthetic data generation: these routes received fuel purchase volumes sized for long-haul distances despite being short-haul corridors, making their per-mile fuel cost appear extreme. They are excluded from the reliable-route margin analysis, counted separately in a dedicated KPI card, and listed by name in the route alert banner on the Route Profitability page.

### Distance Variance Constraints

As documented in the Section 2 findings, actual trip distances in this dataset are constrained to within approximately ±8% of the standard route distance. This is tighter than real-world operational variance and is a synthetic data artifact. It is relevant context for any analysis that compares actual versus expected mileage at the route level.

---

## Theme and Design

The report uses a custom theme file (`FleetTheme.json`) with a five-color system applied consistently across all pages:

| Color | Hex | Usage |
|---|---|---|
| Navy | `#1E3A5F` | Headers, navigation panel, primary text |
| Green | `#2ECC71` | Above-average performance, positive indicators |
| Red | `#E74C3C` | Below-average performance, negative indicators |
| Amber | `#F39C12` | Warning states, mid-range performance |
| Blue | `#2980B9` | Neutral highlights, informational callouts |

Canvas size is 1440×900px with a background color of `#F3F2F1`. Font is Segoe UI throughout.

---

## Limitations

The dashboard inherits the schema limitations documented in [setup/README.md](../setup/README.md). Geographic data uses city and state strings rather than geospatial types, which prevents map-based routing or spatial distance queries. Historical versioning is not implemented in the source schema, so driver status and truck assignments reflect a single point-in-time state rather than a history of changes.

The Import mode connection requires either a manual refresh or a scheduled gateway refresh via Power BI Service to pick up new data. All twelve tables are reloaded in full on each refresh, which scales linearly with data volume.

Row-level security is not implemented. All report consumers see the full dataset across all trucks, routes, drivers, and customers.

The `[Total Maintenance Cost]` measure uses `USERELATIONSHIP()` to filter by `maintenance_date` rather than the active `dispatch_date` path. This means maintenance cost and trip revenue respond to date slicers through different date columns, which can produce counterintuitive totals in period-over-period comparisons if a maintenance event falls in a different month than the trips it supports.

---

## Potential Extensions

- Publish to Power BI Service with a scheduled refresh connected to the MySQL source via an on-premises data gateway
- Implement row-level security roles scoped to truck, route, or customer segment
- Add a driver scorecard page combining on-time rate, MPG quartile, safety incident count, and cumulative miles into a single ranked view
- Build the `driver_scores` history table proposed in [setup/README.md](../setup/README.md) and use it as a persisted KPI source rather than recalculating all metrics from raw events on every visual render
- Replace the static Findings page with a smart narrative visual that generates the summary text dynamically from live measure values
- Extend the Fuel Analysis page with a state-level price map using the Azure Maps visual once the schema adds geospatial columns to the facilities table
