-- ============================================================
-- FILE: trucks_top3_fuel_cost_per_year.sql
-- PURPOSE:
--   Identifies the three highest fuel-spending trucks per
--   calendar year to support fleet cost management.
--
-- BUSINESS CONTEXT:
--   Consistently high fuel spend on specific trucks may
--   indicate mechanical inefficiency, suboptimal route
--   assignment, or high utilization that warrants review.
--   Tracking the top spenders year over year makes it
--   possible to spot whether the same trucks repeatedly
--   appear at the top, which would strengthen the case
--   for maintenance review or replacement.
--
-- APPROACH:
--   The query uses a two-layer structure. The inner subquery
--   aggregates total fuel cost per truck per year from the
--   fuel_purchases table. An INNER JOIN is used intentionally
--   — trucks with no fuel records have no cost to rank and
--   should not appear in the result.
--
--   RANK() is applied in the CTE on the aggregated result,
--   partitioned by year so ranking resets per calendar year.
--   RANK() is chosen over ROW_NUMBER() so that trucks with
--   equal total cost share the same rank — both appear in
--   the result even if that means more than 3 rows for a
--   given year.
--
--   The WHERE clause in the outer query filters on cost_rank
--   to keep only the top 3. This filter is only possible
--   after the window function has been computed in the CTE
--   — window function results cannot be filtered in the
--   same query where they are defined.
--
-- RESULT:
--   Up to 3 trucks per year ordered by rank. Years with
--   ties at rank 3 may return more than 3 rows.
--
-- USE CASES:
--   Fleet cost monitoring, maintenance prioritization,
--   high-utilization truck identification
-- ============================================================

WITH fuel_cost_ranks AS (
    SELECT
        truck_id,
        unit_number,
        make,
        model_year,
        operation_year,
        ROUND(total_cost, 2) AS total_cost,
        RANK() OVER(PARTITION BY operation_year ORDER BY total_cost DESC) AS cost_rank -- Resets per year; ties share the same rank
    FROM (
        -- Aggregates total fuel spend per truck per year
        SELECT
            trucks.truck_id,
            trucks.unit_number,
            trucks.make,
            trucks.model_year,
            YEAR(fuel_purchases.purchase_date) AS operation_year,
            SUM(fuel_purchases.total_cost) AS total_cost
        FROM trucks
        INNER JOIN fuel_purchases ON fuel_purchases.truck_id = trucks.truck_id -- Excludes trucks with no fuel purchases
        GROUP BY
            trucks.truck_id,
            trucks.unit_number,
            trucks.make,
            trucks.model_year,
            YEAR(fuel_purchases.purchase_date)
    ) AS truck_fuel_cost
)

SELECT
    truck_id AS `Truck ID`,
    unit_number AS `Unit Number`,
    make AS `Make`,
    model_year AS `Model Year`,
    operation_year AS `Year`,
    total_cost AS `Total Fuel Cost`,
    cost_rank AS `Rank`
FROM fuel_cost_ranks
WHERE cost_rank <= 3 -- Filters to top 3 per year; only possible after ranking is computed in the CTE
ORDER BY operation_year, cost_rank;
