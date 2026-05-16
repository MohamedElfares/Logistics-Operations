-- ============================================================
-- FILE: drivers_most_recent_trip_distance.sql
-- PURPOSE:
--   Applies LAST_VALUE() to attach each driver's most recent
--   trip distance to every row in their trip history.
--
-- SKILL FOCUS:
--   This query is a targeted exercise in applying LAST_VALUE()
--   correctly, specifically to understand and resolve the
--   default frame clause problem that makes the function
--   behave unexpectedly without explicit configuration.
--
--   By default, window functions use the frame:
--     RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
--
--   With this default, LAST_VALUE() returns the current
--   row's own value at every position — because the current
--   row is always the last row in the default frame. The
--   function becomes indistinguishable from the column itself.
--
--   The fix is to extend the frame explicitly:
--     ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
--
--   This instructs the window to always consider the entire
--   partition from first to last row, so LAST_VALUE() always
--   returns the value from the chronologically last trip
--   regardless of where the current row sits.
--
-- APPROACH:
--   The window is partitioned by driver_id and ordered by
--   dispatch_date so that "last" means the most recent trip
--   within each driver's history. The CTE isolates the
--   window function computation so the outer query can
--   reference most_recent_distance directly without
--   repeating the full expression.
--
-- NOTE:
--   This is a skill-building exercise. The most recent
--   distance value is identical on every row for a given
--   driver, which limits its standalone analytical value.
--   Its practical use would be in comparison or filtering
--   contexts built on top of this base query.
--
-- USE CASES:
--   Skill development — LAST_VALUE(), explicit frame clauses,
--   understanding default vs extended window frame behavior
-- ============================================================

WITH recent_distance AS (
    -- Attaches the most recent trip distance in each driver's history to every row
    SELECT
        drivers.driver_id,
        CONCAT(drivers.first_name, ' ', drivers.last_name) AS driver_name,
        trips.trip_id,
        trips.dispatch_date,
        trips.actual_distance_miles,
        LAST_VALUE(trips.actual_distance_miles)
            OVER(
                PARTITION BY drivers.driver_id
                ORDER BY trips.dispatch_date
                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING  -- Overrides default frame; required for LAST_VALUE() to work correctly
            ) AS most_recent_distance
    FROM trips
    LEFT JOIN drivers ON trips.driver_id = drivers.driver_id
)

SELECT
    driver_id AS `Driver ID`,
    driver_name AS `Driver Name`,
    trip_id AS `Trip ID`,
    dispatch_date AS `Dispatch Date`,
    actual_distance_miles AS `Distance (Miles)`,
    most_recent_distance AS `Most Recent Distance (Miles)`,
    ABS(actual_distance_miles - most_recent_distance) AS `Difference (Miles)`  -- 0 on the driver's last trip; grows for earlier trips
FROM recent_distance
ORDER BY driver_id, dispatch_date;
