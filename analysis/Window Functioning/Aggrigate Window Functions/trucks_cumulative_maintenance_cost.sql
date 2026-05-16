-- ============================================================
-- FILE: trucks_cumulative_maintenance_cost.sql
-- PURPOSE:
--   Computes a running total of maintenance cost per truck
--   ordered by maintenance date, and flags the point at
--   which each truck's cumulative spend crosses $10,000.
--
-- BUSINESS CONTEXT:
--   Total maintenance cost at the end of a truck's service
--   history is a single number that hides when the cost
--   burden became significant. A running total reveals the
--   trajectory — how quickly a truck accumulated costs,
--   whether spending is concentrated in a short period, and
--   at exactly which service event the cumulative cost
--   crossed a meaningful threshold. This supports decisions
--   around whether continued maintenance is more cost-effective
--   than replacement, and at what point that decision should
--   be triggered.
--
-- APPROACH:
--   SUM() is used as a window function in the CTE, partitioned
--   by truck_id so each truck's cumulative total is tracked
--   independently. ORDER BY maintenance_date ensures the
--   accumulation follows the chronological service history.
--
--   The frame clause is left as the default:
--     RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
--   This is appropriate here — unlike LAST_VALUE() and
--   NTH_VALUE(), a running SUM() benefits from the default
--   frame since the goal is to accumulate up to the current
--   row, not across the entire partition.
--
--   A CASE expression in the outer query applies a $10,000
--   threshold flag to each row. Because the flag is applied
--   after the cumulative total is computed in the CTE, it
--   correctly reflects the running state at each service
--   event — not just whether the final total exceeds the
--   threshold.
--
-- RESULT:
--   One row per maintenance record showing labor cost, parts
--   cost, individual service total, cumulative total, and
--   threshold flag. The first row where the flag changes
--   from 'Below Threshold' to 'Over Threshold' identifies
--   the exact service event at which the truck crossed the
--   cost boundary.
--
-- USE CASES:
--   Fleet replacement decision support, maintenance budget
--   monitoring, high-cost truck identification
-- ============================================================

WITH cumulative_maintenance_cost AS (
    -- Computes running total of maintenance cost per truck in chronological order
    SELECT
        truck_id,
        maintenance_type,
        maintenance_date,
        labor_hours,
        labor_cost,
        parts_cost,
        total_cost,
        SUM(total_cost) OVER(
            PARTITION BY truck_id       -- Resets independently for each truck
            ORDER BY maintenance_date   -- Accumulates in chronological service order
        ) AS cumulative_cost
    FROM maintenance_records
)

SELECT
    truck_id AS `Truck ID`,
    maintenance_type AS `Maintenance Type`,
    maintenance_date AS `Maintenance Date`,
    labor_hours AS `Labor (hrs)`,
    ROUND(labor_cost, 2) AS `Labor Cost`,
    ROUND(parts_cost, 2) AS `Parts Cost`,
    ROUND(total_cost, 2) AS `Total Cost`,
    ROUND(cumulative_cost, 2) AS `Cumulative Cost`,
    CASE
        WHEN cumulative_cost > 10000 THEN 'Over Threshold' -- First occurrence marks the threshold crossing event
        ELSE 'Below Threshold'
    END AS `Threshold Flag`
FROM cumulative_maintenance_cost
ORDER BY truck_id, maintenance_date;
