-- ============================================================
-- FILE: active_drivers_ranked_by_miles.sql
-- PURPOSE:
--   Ranks currently active drivers by their total miles
--   driven across all recorded trips.
--
-- APPROACH:
--   A CTE pre-aggregates total miles per driver from the
--   trips table. This is then joined back to the drivers
--   table so that driver details (name, status) can be
--   included alongside the aggregated metric.
--
--   The join starts from drivers rather than the CTE so
--   that active drivers with no trips still appear in the
--   result with 0 miles, rather than being silently excluded.
--   COALESCE handles the NULL that a LEFT JOIN produces
--   when no matching trip record exists.
--
--   RANK() is applied as a window function on the outer
--   query after the join, ordering by total miles descending.
--   Drivers with equal mileage receive the same rank, and
--   the next rank is skipped (e.g. 1, 2, 2, 4).
--
--   COALESCE is also applied inside RANK() to ensure drivers
--   with NULL miles (no trips) sort to the bottom rather
--   than being treated as an unknown value.
--
-- RESULT:
--   One row per active driver showing their name, total
--   miles driven, and rank among all active drivers.
--   Drivers with no trips appear at the bottom with 0 miles.
--
-- USE CASES:
--   Driver productivity ranking, workload distribution
--   analysis, performance benchmarking
-- ============================================================

WITH total_miles_per_driver AS (
    -- Aggregates actual distance driven per driver across all trips
    SELECT
        trips.driver_id                     AS driver_id,
        SUM(trips.actual_distance_miles)    AS total_miles
    FROM trips
    GROUP BY trips.driver_id
)

SELECT
    drivers.driver_id                                       AS `Driver ID`,
    CONCAT(drivers.first_name, ' ', drivers.last_name)     AS `Name`,
    drivers.employment_status                               AS `Status`,
    COALESCE(total_miles_per_driver.total_miles, 0)         AS `Total Distance (Miles)`,  -- 0 for drivers with no trips
    RANK() OVER (
        ORDER BY COALESCE(total_miles_per_driver.total_miles, 0) DESC   -- NULL miles rank last
    )                                                       AS `Rank`
FROM drivers
LEFT JOIN total_miles_per_driver ON drivers.driver_id = total_miles_per_driver.driver_id
WHERE drivers.employment_status = 'Active'  -- Terminated drivers excluded
ORDER BY `Rank`;
