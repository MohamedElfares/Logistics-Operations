-- ============================================================
-- FILE: truck_operating_costs_by_year.sql
-- PURPOSE:
--   Compares annual fuel cost and maintenance cost side by
--   side for each truck, and computes total operating cost
--   per truck per year.
--
-- APPROACH:
--   Two independent CTEs aggregate costs from separate tables:
--
--   CTE 1 — fuel_cost_per_truck:
--     Joins trucks to fuel_purchases and groups by truck and
--     year to produce total annual fuel spend per truck.
--
--   CTE 2 — maintenance_cost_per_truck:
--     Joins trucks to maintenance_records and groups by truck
--     and year to produce total annual maintenance spend.
--
--   The two CTEs are joined on truck_id AND year so that
--   costs are compared within the same calendar year.
--   A LEFT JOIN is used so that trucks with fuel records
--   but no maintenance in a given year still appear — with
--   0 in the maintenance column rather than being excluded.
--
--   COALESCE is applied to both cost columns to replace NULL
--   (no records found) with 0, making the total operating
--   cost calculation safe from NULL propagation.
--
-- NOTE ON NULL YEARS:
--   Trucks with no fuel purchases produce a NULL year group
--   in fuel_cost_per_truck (YEAR(NULL) = NULL). These are
--   filtered out in the outer query with WHERE year IS NOT NULL
--   to avoid meaningless rows in the result.
--
-- RESULT:
--   One row per truck per year showing fuel cost, maintenance
--   cost, and combined total operating cost. Years with no
--   fuel records are excluded. Years with fuel but no
--   maintenance show 0 in the maintenance column.
--
-- USE CASES:
--   Fleet cost analysis, operating budget planning,
--   identifying high-cost trucks for replacement decisions
-- ============================================================

WITH fuel_cost_per_truck AS (
    -- Total fuel spend per truck per year
    SELECT
        trucks.truck_id                         AS truck_id,
        YEAR(fuel_purchases.purchase_date)      AS year,
        SUM(fuel_purchases.total_cost)          AS fuel_cost
    FROM trucks
    LEFT JOIN fuel_purchases ON fuel_purchases.truck_id = trucks.truck_id
    GROUP BY
        trucks.truck_id,
        YEAR(fuel_purchases.purchase_date)
),

maintenance_cost_per_truck AS (
    -- Total maintenance spend per truck per year
    SELECT
        trucks.truck_id                             AS truck_id,
        YEAR(maintenance_records.maintenance_date)  AS year,
        SUM(maintenance_records.total_cost)         AS maintenance_cost
    FROM trucks
    LEFT JOIN maintenance_records ON maintenance_records.truck_id = trucks.truck_id
    GROUP BY
        trucks.truck_id,
        YEAR(maintenance_records.maintenance_date)
)

SELECT
    fuel_cost_per_truck.truck_id                                                        AS `Truck ID`,
    fuel_cost_per_truck.year                                                            AS `Year`,
    COALESCE(ROUND(fuel_cost_per_truck.fuel_cost, 2), 0)                                AS `Fuel Cost`,
    COALESCE(ROUND(maintenance_cost_per_truck.maintenance_cost, 2), 0)                  AS `Maintenance Cost`,  -- 0 if no maintenance records for that year
    ROUND(
        COALESCE(fuel_cost_per_truck.fuel_cost, 0)
        + COALESCE(maintenance_cost_per_truck.maintenance_cost, 0)
    , 2)                                                                                AS `Total Operating Cost`
FROM fuel_cost_per_truck
LEFT JOIN maintenance_cost_per_truck ON
    fuel_cost_per_truck.truck_id = maintenance_cost_per_truck.truck_id
    AND fuel_cost_per_truck.year = maintenance_cost_per_truck.year  -- Match within the same calendar year
WHERE fuel_cost_per_truck.year IS NOT NULL   -- Removes NULL year groups from trucks with no fuel purchases
ORDER BY fuel_cost_per_truck.truck_id, fuel_cost_per_truck.year ASC;
