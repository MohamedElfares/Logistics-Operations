# Fleet Performance Dashboard — Session Compact
**Last updated:** 2026-06-12 | **Analyst:** Mohamed | **Tool:** Power BI Desktop + MySQL 8.0 + MCP
**Supersedes:** fleet_dashboard_compact_20260611.md

---

## How to use this file
Paste at the top of any new conversation to resume work on this project without re-explaining context.
Claude will have full knowledge of the model state, all decisions made, and what remains to do.

---

## Project Identity
- **File:** Fleet Performance Dashboard.pbix
- **Backend:** MySQL localhost — logistics database (12 tables, Jan 2022 – Dec 2024)
- **Dataset:** 80,458 trips · 85,410 loads · 120 trucks · 150 drivers · 200 customers · 58 routes
- **Measures table:** `_Measures` (single-s — corrected from `_Measuress` in Session 4)
- **Measure count:** 130 measures across 16 display folders
- **Goal:** Fleet profitability + asset utilization BI portfolio project for job interviews / GitHub
- **Teaching approach:** Claude provides logic and DAX patterns; Mohamed writes all DAX himself for review

---

## Architecture Decisions (Final, Locked)

### Connection & Storage
- **Mode:** Import (not DirectQuery) — dataset ~150MB, needs full DAX support
- **Source:** MySQL via MySQL Connector/ODBC 8.0 (64-bit)
- **Measures table:** `_Measures` — all 130 measures live here

### Data Model
- **Schema:** Hybrid star + snowflake, TRIPS as central fact table
- **Loads ↔ Trips:** 1:1, Both directions (same operational event, two perspectives)
- **Dims → Trips:** 1:Many, Single direction
- **Inactive relationships:** Trucks→FuelPurchases, Trucks→MaintenanceRecords, Trucks→SafetyIncidents, Drivers→FuelPurchases, Drivers→SafetyIncidents, Trips→DeliveryEvents
- **Date table:** DAX ADDCOLUMNS(CALENDAR(...)) — dynamic range MIN/MAX(Trips[dispatch_date])
- **Active Date path:** Date → Trips[dispatch_date] ONLY (all other Date→fact links are inactive)
- **Auto date/time:** DISABLED

### Key Data Quality Facts
| Finding | Value |
|---------|-------|
| Orphaned loads (no matching trip) | 4,952 (5.8%) = $15.25M unattributed revenue |
| Active trucks (≥1 trip) | 92 of 120 registered (28 never dispatched) |
| Flagged routes (fuel anomaly) | 6 routes: RTE00010, 15, 33, 36, 47, 58 ($2.07–$12.38/mi vs $0.83 fleet avg) |
| Trips total | 80,458 |
| Loads total | 85,410 |
| FK violation reason | MySQL rejected trips with missing FK refs during original data import |

---

## Measure Folder Structure — 130 measures total

```
_Measures
├── Base Counts                    (6)
├── Revenue                        (5)
├── Fleet Performance              (4)
├── Cost & Efficiency              (6)
├── Route Profitability            (2)
├── Delivery Performance           (3)
├── Time Intelligence              (3)
├── Visual Formatting              (4)
├── Targets & Config               (5)
├── Safety & Maintenance           (19)
├── Executive Summary Page         (10)   ← uppercase P, confirmed Session 4
├── Fleet Performance Page         (15)
├── Route Profitability Page       (11)
├── Delivery Performance Page      (15)
├── Fuel Analysis Page             (10)
└── Fuel Insights                  (12)
```

> No "Page Header" folder exists in the model. All page-level measures were created
> directly in their correct page folders.

---

## Complete Measure Inventory

### Base Counts (6)
| Measure | Expression summary | Notes |
|---------|-------------------|-------|
| `Trips Count` | `COUNTROWS(Trips)` | ✅ |
| `Loads Count` | `COUNTROWS(Loads)` | ✅ |
| `Loads with Trip Data` | `CALCULATE([Loads Count], TREATAS(VALUES(Trips[load_id]), Loads[load_id]))` | ✅ TREATAS semi-join |
| `Deliveries Count` | `COUNTROWS('Delivery Events')` | ✅ |
| `Total Trucks` | `CALCULATE(COUNTROWS(Trucks), REMOVEFILTERS())` | ✅ always 120 |
| `Total Miles Driven` | `SUM(Trips[actual_distance_miles])` | ✅ |

### Revenue (5)
| Measure | Expression summary | Notes |
|---------|-------------------|-------|
| `Total Revenue` | `SUM(Loads[revenue])` | ✅ includes $15.25M orphaned loads |
| `Revenue with Trip Data` | CALCULATE + TREATAS semi-join | ✅ attributed only ($247.3M) |
| `Revenue Missing Trip Data` | `[Total Revenue] - [Revenue with Trip Data]` | ✅ $15.25M gap |
| `Avg Revenue per Truck` | Both VARs use REMOVEFILTERS() | ✅ ~$2.69M unfiltered header ref |
| `Loads Missing Trip Data %` | `DIVIDE([Loads Count] - [Loads with Trip Data], [Loads Count])` | ✅ 5.8% |

### Fleet Performance (4)
| Measure | Expression summary | Notes |
|---------|-------------------|-------|
| `Active Trucks` | `DISTINCTCOUNT(Trips[truck_id])` | ✅ slicer-responsive |
| `Active Truck-Days` | `SUMX(VALUES(Trips[dispatch_date]), CALCULATE(DISTINCTCOUNT(Trips[truck_id])))` | ✅ SUMX pattern |
| `Available Truck-Days` | `COUNTROWS('Date') * [Total Trucks]` | ✅ |
| `Fleet Utilization Rate` | `DIVIDE([Active Truck-Days], [Available Truck-Days])` | ✅ 42.14% avg vs 70% target |

### Cost & Efficiency (6)
| Measure | Expression summary | Notes |
|---------|-------------------|-------|
| `Total Fuel Cost` | `SUM('Fuel Purchases'[total_cost])` | ✅ $90.1M |
| `Total Maintenance Cost` | CALCULATE + USERELATIONSHIP(Date, maintenance_date) | ✅ filters by service date |
| `Total Operating Costs` | `[Total Fuel Cost] + [Total Maintenance Cost]` | ✅ |
| `Avg Cost/Mile` | `DIVIDE([Total Operating Costs], [Total Miles Driven])` | ✅ $0.83/mi fleet avg |
| `Fuel Cost per Mile` | `DIVIDE([Total Fuel Cost], [Total Miles Driven])` | ✅ base for $2.00 flagging threshold |
| `Allocated Maintenance` | VAR RouteShare × [Total Maintenance Cost] | ✅ uses REMOVEFILTERS(Routes) for denominator |

### Route Profitability (2)
| Measure | Expression summary | Notes |
|---------|-------------------|-------|
| `Route Profit Margin` | `VAR Rev = [Revenue with Trip Data]` → DIVIDE(Rev − Fuel − Maintenance, Rev) | ✅ 63.52% avg |
| `Route Profit Margin (Fuel)` | `VAR Rev = [Revenue with Trip Data]` → DIVIDE(Rev − Fuel, Rev) | ✅ 65.70% avg · fuel-only view |

> **Critical rule:** ALWAYS use `[Revenue with Trip Data]` as the revenue base in both margin
> measures — NOT `[Total Revenue]`. Total Revenue includes $15.25M from orphaned loads that
> have no truck, driver, or route attribution.

### Delivery Performance (3)
| Measure | Expression summary | Notes |
|---------|-------------------|-------|
| `On-Time Deliveries` | CALCULATE + `on_time_flag = TRUE()` | ✅ 89,603 |
| `Late Deliveries` | CALCULATE + `on_time_flag = FALSE()` | ✅ 71,313 |
| `On-Time Delivery Rate` | `DIVIDE([On-Time Deliveries], [Deliveries Count])` | ✅ 55.68% fleet avg |

### Time Intelligence (3)
| Measure | Expression summary | Notes |
|---------|-------------------|-------|
| `Revenue YTD` | `TOTALYTD([Revenue with Trip Data], 'Date'[Date])` | ✅ no redundant outer CALCULATE |
| `Prior Revenue` | `CALCULATE([Revenue with Trip Data], SAMEPERIODLASTYEAR('Date'[Date]))` | ✅ |
| `YoY Growth %` | `DIVIDE([Revenue with Trip Data] - [Prior Revenue], [Prior Revenue])` | ✅ format: `+0.00%;-0.00%;0.00%` |

### Visual Formatting (4)
| Measure | Purpose | Notes |
|---------|---------|-------|
| `Revenue Bar Color` | Green ≥ fleet avg · Red below | ✅ AVERAGEX + REMOVEFILTERS(Trucks) |
| `Cost per Mile Bar Color` | Green ≤ fleet avg · Red above (reversed) | ✅ |
| `Fleet Utilization Bar Color` | ≥60% Green · ≥40% Amber · <40% Red | ✅ REMOVEFILTERS removed from VAR (was bug) |
| `On-Time Bar Color` | >60% Green · >50% Amber · ≤50% Red | ✅ |

### Targets & Config (5)
| Measure | Value | Notes |
|---------|-------|-------|
| `Target Fleet Utilization Rate` | `0.70` | ✅ 70% benchmark |
| `Target On-Time Rate` | `0.80` | ✅ 80% industry benchmark |
| `Flagged Routes Count` | CALCULATE + FILTER(Routes, [Fuel Cost per Mile] > 2.00) | ✅ FILTER wrapper required |
| `Reliable Route Counts` | CALCULATE + FILTER(Routes, [Fuel Cost per Mile] <= 2.00) | ✅ 52 routes |
| `Report Last Refreshed` | VAR RefreshDate + IF(TODAY()) pattern | ✅ in Last Refresh table |

### Safety & Maintenance (19)
#### Base measures
| Measure | Expression summary | Notes |
|---------|-------------------|-------|
| `Incidents Count` | `COUNTROWS('Safety Incidents')` | ✅ renamed from `Incedients Counts` (typo) |
| `Incidents Claims` | `SUM('Safety Incidents'[claim_amount])` | ✅ column is `claim_amount` not `claim_value` |
| `Maintenance Records` | `COUNTROWS('Maintenance Records')` | ✅ |
| `Maintenance Cost` | `SUM('Maintenance Records'[total_cost])` | ✅ base for [Maintenance % Revenue] and header KPI only — NOT for [Allocated Maintenance] |
| `Avg Downtime / Service` | `AVERAGE('Maintenance Records'[downtime_hours])` | ✅ ~24.7h fleet avg |
| `Fault Flag Counts` | CALCULATE + `at_fault_flag = TRUE()` | ✅ BOOLEAN filter |
| `Injuries Flag Counts` | CALCULATE + `injury_flag = TRUE()` | ✅ |
| `Preventable Flag Counts` | CALCULATE + `preventable_flag = TRUE()` | ✅ |
| `At-Fault %` | `DIVIDE([Fault Flag Counts], [Incidents Count])` | ✅ ~33% fleet avg |
| `Most Expensive Maintenance Type` | SUMMARIZE by type → TOPN(1) → CONCATENATEX | ✅ groups by type, not individual row |

#### Header KPIs (🏷️)
| Measure | Returns | Notes |
|---------|---------|-------|
| `🏷️ Report Subtitle (Safety & Maintenance)` | "X incidents · Y records · $Z claims · N% of revenue" | ✅ all REMOVEFILTERS |
| `🏷️ Total Incidents` | CALCULATE([Incidents Count], REMOVEFILTERS()) | ✅ renamed from `🏷️ Total Maintenance` (was wrong) |
| `🏷️ Total Claims` | CALCULATE([Incidents Claims], REMOVEFILTERS()) | ✅ |
| `🏷️ Total Maintenance Cost` | CALCULATE([Maintenance Cost], REMOVEFILTERS()) | ✅ renamed from `🏷️ Maint cost` |

#### KPI Labels (📌)
| Measure | Returns | Notes |
|---------|---------|-------|
| `📌 Avg Downtime / Service` | `FORMAT([Avg Downtime / Service], "0.0") & " h"` | ✅ e.g. "24.7 h" · slicer-responsive |
| `📌 Incident Coverage Period` | "Over 3 years" — DISTINCTCOUNT years + REMOVEFILTERS | ✅ renamed from `📌 Incedients Interval` (typo) · shows TIME SPAN not frequency |
| `📌 Avg Claim per Incident` | AVERAGE(claim_amount)/1000 → "$14.2K avg per incident" | ✅ renamed from `📌 AVG Claim/Incident` · slicer-responsive |
| `📌 Maintenance % Revenue` | CALCULATE([Maintenance Cost]/[Revenue with Trip Data], REMOVEFILTERS()) | ✅ "2.32% of revenue" |
| `📌 Downtime Note` | Dynamic: spread check across types → "Consistent (Xh range)" or "Variance detected" | ✅ ADDCOLUMNS + MAXX/MINX pattern |

### Executive Summary Page (10)
| Measure | Returns | Notes |
|---------|---------|-------|
| `🏷️ Report Time Span` | "3 Years" — REMOVEFILTERS | ✅ |
| `🏷️ Total Trips — All Time` | 80,458 — REMOVEFILTERS | ✅ |
| `🏷️ Report Subtitle (Executive Summary)` | "Jan 2022 - Dec 2024 • MySQL Logistics DB • 12 Tables" | ✅ dynamic MIN/MAX dates |
| `📌 Idle Trucks Note` | "28 trucks never dispatched" | ✅ |
| `⚠️ Data Quality Alert Banner (Executive Summary)` | 5-VAR dynamic alert string | ✅ fully REMOVEFILTERS |
| `📌 Revenue Attribution Note` | Static "Attributed Fleet Only" | ✅ |
| `📌 Miles Context Note` | "Across 80,458 trips" — CALCULATE([Trips Count], REMOVEFILTERS()) | ✅ REMOVEFILTERS confirmed present |
| `📌 Data Quality Gap %` | CALCULATE([Loads Missing Trip Data %], REMOVEFILTERS()) — 5.8% | ✅ |
| `📌 Data Gap Details` | "$15.2M unattributed • 4,952 loads" | ✅ |
| `📌 YoY Growth Label` | "2023→2024" — MAX('Date'[Year]) WITHOUT CALCULATE | ✅ renamed from `📌 YOY Growth Label` (casing) |

> **`📌 YoY Growth Label` pattern:** Use `MAX('Date'[Year])` — never `CALCULATE(MAX(...))`.
> CALCULATE breaks visual axis context inheritance and causes "-1→" output bug.

### Fleet Performance Page (15)
#### Header KPIs (🏷️)
| Measure | Returns | Notes |
|---------|---------|-------|
| `🏷️ Report Subtitle (Fleet Performance)` | "92 active trucks • 6 manufacturers • 2015–2021 model years" | ✅ all REMOVEFILTERS |
| `🏷️ Active Trucks` | "92 / 120" — both REMOVEFILTERS | ✅ |
| `🏷️ Avg Cost/Mile` | $0.83 — REMOVEFILTERS | ✅ |
| `🏷️ Fleet Utilization Rate` | 42.1% — REMOVEFILTERS | ✅ |

#### KPI Labels (📌)
| Measure | Returns | Notes |
|---------|---------|-------|
| `📌 Total Truck Note` | Static "Fleet Registry" | ✅ |
| `📌 Active Trucks Note` | "Had ≥1 trips • 23% inactive" | ✅ [Active Trucks] in InactivePct IS slicer-responsive; only [Total Trucks] is REMOVEFILTERS |
| `📌 Avg Cost/Mile Note` | "Range $0.74–$0.91" — ADDCOLUMNS iteration | ✅ |
| `📌 Miles Card Context Note` | "80,458 trips" — CALCULATE([Trips Count], REMOVEFILTERS()) | ✅ |
| `📌 Revenue Gap to Max` | Axis padding: 1.075 × MaxRevenue − TruckRevenue | ✅ USD format confirmed |
| `📌 Revenue vs Fleet Average Note` | "Fleet avg $2.7M · Green = above average · Red = below" | ✅ dynamic — embeds live FORMAT value |
| `📌 Cost Efficiency Gap to Max` | Axis padding for Cost/Mile stacked bar | ✅ |
| `📌 Active Trucks — Unfiltered` | Always 92 — REMOVEFILTERS | ✅ |
| `📌 Efficiency` | "Efficient" / "Slightly above" — HASONEVALUE guard | ✅ |
| `📌 Cost Chart Subtitle` | "Red bars → above fleet average $0.83" — FORMAT("$0.00") | ✅ |
| `📌 Truck Utilization Rate` | Per-truck: active days ÷ 1-truck capacity (NOT fleet capacity) | ✅ |

### Route Profitability Page (11)
#### Header KPIs (🏷️)
| Measure | Returns | Notes |
|---------|---------|-------|
| `🏷️ Report Subtitle (Route Profitability)` | "58 routes • 6 flagged • avg margin 63.5%" | ✅ |
| `🏷️ Reliable Routes (Route Profitability)` | 52 — REMOVEFILTERS | ✅ |
| `🏷️ Flagged Routes (Route Profitability)` | 6 — REMOVEFILTERS | ✅ |

#### KPI Labels (📌) + Alert (⚠️)
| Measure | Returns | Notes |
|---------|---------|-------|
| `📌 Total Routes` | 58 — REMOVEFILTERS | ✅ |
| `📌 Avg Profit Margin Note` | Static "After fuel + maintenance" | ✅ static string, no computed values |
| `📌 Flagged Routes Note` | Static "Fuel Cost > $2.00/mi" | ✅ |
| `📌 Avg Cost/Mile Reliable` | CALCULATE([Avg Cost/Mile], FILTER(Routes, [Fuel Cost per Mile] <= 2.00)) | ✅ |
| `📌 Avg Cost/Mile Reliable Note` | "Reliable routes only · $0.78/mi" — embeds live value | ✅ dynamic |
| `📌 Best Profit Margin` | MAXX over Routes + REMOVEFILTERS — 83.5% | ✅ |
| `📌 Avg Profit Margin` | CALCULATE([Route Profit Margin], REMOVEFILTERS()) — 63.52% | ✅ |
| `⚠️ Route Alert Banner (Route Profitability)` | Dynamic: 6 flagged routes + cost range | ✅ |

### Delivery Performance Page (15)
#### Header KPIs (🏷️)
| Measure | Returns | Notes |
|---------|---------|-------|
| `🏷️ Report Subtitle (Delivery Performance)` | "200 customers · 160,916 deliveries · systemic 55.7% on-time rate" | ✅ |
| `🏷️ On-Time Benchmark Gap` | "-24pp" — (On-Time Rate − 80% target) × 100 + REMOVEFILTERS | ✅ |
| `🏷️ On-Time Delivery Rate` | CALCULATE([On-Time Delivery Rate], REMOVEFILTERS()) — 55.7% | ✅ |
| `🏷️ Late Deliveries` | CALCULATE([Late Deliveries], REMOVEFILTERS()) — 71,313 | ✅ |

#### KPI Labels (📌)
| Measure | Returns | Notes |
|---------|---------|-------|
| `📌 On-Time Benchmark Note` | "Benchmark: 80%  ·  Actual: 55.7%" — both REMOVEFILTERS | ✅ |
| `📌 Contract Customers Rate` | ~55.7% — type filter + REMOVEFILTERS on other tables | ✅ |
| `📌 Spot Customers Rate` | ~55.9% | ✅ |
| `📌 Dedicated Customers Rate` | ~55.5% | ✅ verified working |
| `📌 Contract Customers title` | "Contract Customers (75)" — dynamic count | ✅ |
| `📌 Spot Customers title` | "Spot Customers (63)" | ✅ |
| `📌 Dedicated Customers title` | "Dedicated Customers (62)" | ✅ |
| `📌 Contract Customers Note` | "$93M rev · 32,209 loads" | ✅ |
| `📌 Spot Customers Note` | "$78M rev · 26,856 loads" | ✅ |
| `📌 Dedicated Customers Note` | "$76M rev · 26,345 loads" | ✅ |
| `📌 On-Time Performance Category` | "Above Average"/"Average"/"Below Average" — ±1pp band, HASONEVALUE guard | ✅ |

### Fuel Analysis Page (10)
#### Header KPIs (🏷️)
| Measure | Returns | Notes |
|---------|---------|-------|
| `🏷️ Report Subtitle (Fuel Analysis)` | "82,300 transactions · 12 states · $90.1M total · avg $3.91/gallon" | ✅ format "#,0" (locale-safe) |
| `🏷️ Total Fuel Cost` | CALCULATE([Total Fuel Cost], REMOVEFILTERS()) — $90.1M | ✅ |
| `🏷️ Fleet MPG` | CALCULATE(AVERAGE(Trips[average_mpg]), REMOVEFILTERS()) | ✅ format "0.00" added · compare to [Fleet MPG (Calculated)] |
| `🏷️ % of revenue` | CALCULATE(DIVIDE([Total Fuel Cost], [Revenue with Trip Data]), REMOVEFILTERS()) — 36.4% | ✅ unfiltered header ref |

#### KPI Labels (📌)
| Measure | Returns | Notes |
|---------|---------|-------|
| `📌 % of revenue` | "36.4% of total revenue" — FORMAT(DIVIDE(...), "0.0%") | ✅ slicer-responsive (NO REMOVEFILTERS) · single space fixed |
| `📌 FuelPurchasesTransactions` | "Across 82.3K+ transactions" — FORMAT(DIVIDE(COUNTROWS,1000), "0.0") | ✅ |
| `📌 Fleet Avg MPG` | "115M mi / 23.1M gal · 4.97 MPG" — embeds ratio-based MPG | ✅ |
| `📌 Avg Price/Gallon Range by State` | "Fleet avg: $3.91/gal · Range: $3.74–$4.12 by state" | ✅ renamed from `📌 Avg Gallons Range` |
| `📌 Total Fuel Cost/State` | "TX & TN — 15.9% of total fuel spend" — SUMMARIZE + TOPN(2) | ✅ dynamic |
| `📌 3-Month Avg Fuel Cost` | TOPN(3 months) → AVERAGEX rolling avg | ✅ USD format |

### Fuel Insights (12)
| Measure | Expression summary | Format | Notes |
|---------|-------------------|--------|-------|
| `Total Gallons Consumed` | `SUM('Fuel Purchases'[gallons])` | `#,0.0` | ✅ base denominator |
| `Fleet MPG (Calculated)` | `DIVIDE([Total Miles Driven], [Total Gallons Consumed])` | `0.00` | ✅ ratio method — more accurate than avg of avgs |
| `Avg Price per Gallon` | `DIVIDE(SUM(total_cost), SUM(gallons))` | `$#,0.00` | ✅ volume-weighted avg |
| `Fuel Cost per Trip` | `DIVIDE([Total Fuel Cost], [Trips Count])` | `$#,0.00` | ✅ ~$1,119 fleet avg |
| `Fuel % of Total Revenue` | `DIVIDE([Total Fuel Cost], [Revenue with Trip Data])` | `0.0%` | ✅ 36.4% · slicer-responsive |
| `Prior Period Fuel Cost` | `CALCULATE([Total Fuel Cost], SAMEPERIODLASTYEAR('Date'[Date]))` | `$#,0.0` | ✅ BLANK for 2022 |
| `Fuel Cost YoY %` | `DIVIDE([Total Fuel Cost] - [Prior Period Fuel Cost], [Prior Period Fuel Cost])` | `0.00%` | ✅ positive = unfavorable |
| `Top Fuel Spend State` | SUMMARIZE → TOPN(1) → CONCATENATEX | string | ✅ e.g. "TX" |
| `Avg MPG per Truck (Numeric)` | `AVERAGE(Trips[average_mpg])` | `0.00` | ✅ fully slicer-responsive |
| `Fuel Efficiency Rating` | SWITCH vs FleetAvgMPG ±10% → "High efficiency"/"Average"/"Below avg" | string | ✅ HASONEVALUE guard |
| `MPG Bar Color` | SWITCH vs FleetAvgMPG ±10% → "#2ECC71"/"#F39C12"/"#E74C3C" | string | ✅ apply via Format > Bars > fx > Field value |
| `Fuel Cost Rolling 3M Avg` | `CALCULATE([Total Fuel Cost], DATESINPERIOD('Date'[Date], MAX('Date'[Date]), -3, MONTH))` ÷ 3 | `$#,0.0` | ✅ SemanticError fixed — MAX inlined, no VAR |

> **`Fuel Cost Rolling 3M Avg` rule:** Never store `MAX('Date'[Date])` in a VAR and pass it
> to DATESINPERIOD inside CALCULATE — Power BI rejects the VAR reference as the anchor date.
> Always inline `MAX('Date'[Date])` directly inside the DATESINPERIOD call.

---

## Rename & Fix History

### Session 2 — Renames
| Old name | New name | Reason |
|----------|----------|--------|
| `Incedients Counts` | `Incidents Count` | Typo |
| `📌 Incedients Interval` | `📌 Incident Coverage Period` | Typo + clarity |
| `📌 AVG Claim/Incident` | `📌 Avg Claim per Incident` | Consistent casing |
| `🏷️ Maint cost` | `🏷️ Total Maintenance Cost` | Naming convention |
| `📌 Avg Gallons Range` | `📌 Avg Price/Gallon Range by State` | Expression computed price, not volume |
| `🏷️ Total Maintenance` | `🏷️ Total Incidents` | Expression counted incidents, not maintenance |

### Session 4 — Renames & Fixes
| Item | Change | Reason |
|------|--------|--------|
| `_Measuress` table | → `_Measures` | Double-s typo — renamed by user in Power BI |
| `📌 YOY Growth Label` | → `📌 YoY Growth Label` | Inconsistent casing vs `YoY Growth %` |
| `Executive Summary page` folder | → `Executive Summary Page` | Casing inconsistency vs all other page folders |
| `Fuel Cost Rolling 3M Avg` | DAX SemanticError fixed | VAR anchor in DATESINPERIOD → inlined MAX |
| `📌 % of revenue` | Double space removed in output string | "of  total" → "of total" |
| `📌 Revenue vs Fleet Average Note` | Description fixed | Removed false "Static" label — measure is dynamic |
| `📌 Incident Coverage Period` | Description fixed | Was "frequency/interval" — actually shows time span |
| `Incidents Claims` | Description fixed | `claim_value` → `claim_amount` (correct column name) |
| `🏷️ Fleet MPG` | Description fixed | Cross-ref `[Fleet MPG Calculated]` → `[Fleet MPG (Calculated)]` |
| `Maintenance Cost` | Description fixed | Removed false claim it bases `[Allocated Maintenance]` |
| `📌 Avg Profit Margin Note` | Description fixed | Was wrong — measure is static "After fuel + maintenance" |
| `📌 Active Trucks Note` | Description fixed | Removed "All calculations use REMOVEFILTERS()" — InactivePct is slicer-responsive |
| `📌 YoY Growth Label` | Expression comment cleaned | Removed "OPTIMIZATION FIX:" changelog noise |

---

## Dashboard Pages (7 Pages)

### Design System
- **Theme:** FleetTheme.json imported
- **Colors:** Navy #1E3A5F · Green #2ECC71 · Red #E74C3C · Amber #F39C12 · Blue #2980B9
- **Font:** Segoe UI · **Canvas:** 1440×900px · **Background:** #F3F2F1 / #E8E6E3

### Status
| Page | Status | Outstanding issues |
|------|--------|--------------------|
| Executive Summary | ✅ Complete | None |
| Fleet Performance | ✅ Complete | None |
| Route Profitability | ✅ Complete | None |
| Delivery Performance | ✅ Complete | None |
| Safety & Maintenance | ✅ Complete | None |
| Fuel Analysis | ✅ Complete | None |
| Findings & Insights | ✅ Complete | None |

---

## Deliverables Created
| File | Description |
|------|-------------|
| `fleet_performance_analysis.html` | 8-section analytics dashboard (Chart.js) |
| `fleet_pbi.html` | Full Power BI look-alike shell (7 pages, nav, filter pane) |
| `powerbi_implementation_guide.html` | 14-section implementation guide (theme JSON, specs, RLS) |
| `er_diagram.html` | Interactive ER diagram with PNG export (1×/2×/3×) |
| `er_diagram_base.png` | 1769×1573px ER diagram |
| `er_diagram_2x_HD.png` | 3538×3146px @ 300 DPI |

---

## Pending Tasks

### All previous tasks resolved ✅
Everything from Sessions 1–4 is complete. The only remaining work is publishing.

### Remaining
1. **Phase 6 — Publishing**
   - Power BI Gateway setup for scheduled MySQL refresh
   - Scheduled refresh configuration (daily recommended)
   - Row-Level Security (RLS) roles if needed
   - Power BI App packaging for distribution
   - README + GitHub portfolio write-up

2. **Optional — `🏷️ Utilization Gap vs Target`** (Fleet Performance page)
   - Was listed in prior compact as "possible addition"
   - Not in model; build if needed:
   ```dax
   FORMAT((CALCULATE([Fleet Utilization Rate], REMOVEFILTERS()) - [Target Fleet Utilization Rate]) * 100, "0") & "pp gap to target"
   ```

---

## MCP Session Notes

### Connection pattern (required every session)
```
1. powerbi-modeling-mcp → connection_operations → ListLocalInstances
2. Copy the connectionString from the result
3. connection_operations → Connect with that connectionString
4. Port changes every time Power BI reopens — always rediscover
```

### Batch operation settings
```json
"options": { "continueOnError": true, "useTransaction": true }
```

### Key rules
- **Table name:** `_Measures` (single-s) — always use this exact name
- **Rename before Update** — always `Rename` first, then `Update` in a separate call
- **FILTER() wrapper required** for measure predicates on dimension tables (e.g. Routes) — direct boolean predicate fails silently
- **Dependency cascade on renames** — immediately update all measures that reference a renamed measure in the same session
- **DAX query for bulk retrieval:** `INFO.MEASURES()` is the most reliable way to pull all 130 expressions at once when Get returns truncated context

---

## Key DAX Patterns

```dax
-- Semi-join (attributed loads only)
CALCULATE([Loads Count], TREATAS(VALUES(Trips[load_id]), Loads[load_id]))

-- Per-dimension day count (SUMX > SUMMARIZE for performance)
SUMX(VALUES(Trips[dispatch_date]), CALCULATE(DISTINCTCOUNT(Trips[truck_id])))

-- Dimension table predicate (FILTER wrapper is REQUIRED — direct boolean fails)
CALCULATE(COUNTROWS(Routes), FILTER(Routes, [Fuel Cost per Mile] > 2.00))

-- Route margin — ALWAYS use [Revenue with Trip Data], never [Total Revenue]
VAR Rev = [Revenue with Trip Data]
RETURN DIVIDE(Rev - [Total Fuel Cost] - [Allocated Maintenance], Rev)

-- Dynamic subtitle pattern
VAR Val1 = FORMAT(CALCULATE([Measure1], REMOVEFILTERS()), "#,0")
VAR Val2 = FORMAT(CALCULATE([Measure2], REMOVEFILTERS()), "0.0%")
RETURN Val1 & " label · " & Val2 & " label"

-- YoY label (axis context — do NOT wrap MAX in CALCULATE)
VAR CurrentYear = MAX('Date'[Year])   -- NOT CALCULATE(MAX(...))
VAR PriorYear = CurrentYear - 1
RETURN FORMAT(PriorYear, "0") & "→" & FORMAT(CurrentYear, "0")

-- TOPN dynamic text (top-N from aggregated table)
VAR Summary = SUMMARIZE(Table, Table[Column], "Metric", SUM(Table[Value]))
VAR TopN    = TOPN(1, Summary, [Metric], DESC)
RETURN CONCATENATEX(TopN, Table[Column])

-- Rolling N-month average (inline MAX — never use VAR inside DATESINPERIOD)
VAR RollingCost = CALCULATE(
    [Total Fuel Cost],
    DATESINPERIOD('Date'[Date], MAX('Date'[Date]), -3, MONTH)
)
RETURN DIVIDE(RollingCost, 3)

-- Dynamic variance note (spread check across a dimension)
VAR TypeTable = ADDCOLUMNS(VALUES(Table[Dimension]), "Metric", CALCULATE(AVERAGE(Table[Value])))
VAR Spread    = MAXX(TypeTable, [Metric]) - MINX(TypeTable, [Metric])
RETURN IF(
    ISBLANK(Spread), "No data",
    IF(Spread <= 2, "Consistent (" & FORMAT(Spread, "0.0") & "h range)",
       "Variance detected — " & FORMAT(Spread, "0.0") & "h spread")
)
```

---

*Paste this file at the top of a new conversation to resume the Fleet Performance Dashboard project.
All 130 measures are live, clean, and error-free. Resume from "Pending Tasks → Phase 6 Publishing".*
