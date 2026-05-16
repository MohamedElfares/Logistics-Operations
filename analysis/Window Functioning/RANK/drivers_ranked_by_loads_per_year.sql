-- ============================================================
-- FILE: drivers_ranked_by_loads_per_year.sql
-- PURPOSE:
--   Ranks drivers by total loads completed within each
--   calendar year, using RANK() to surface ties.
--
-- BUSINESS CONTEXT:
--   Comparing driver productivity year over year helps
--   identify consistently high-performing drivers and spot
--   those whose output has declined. RANK() is used instead
--   of ROW_NUMBER() so that drivers with equal load counts
--   receive the same rank rather than an arbitrary ordering.
--
-- APPROACH:
--   A CTE pre-aggregates total loads per driver per year
--   from the trips table, joined to loads for the load date
--   and to drivers for the name. The window function is then
--   applied in the outer query on the already-computed total,
--   partitioned by year so ranking resets independently for
--   each calendar year.
--
-- RESULT:
--   One row per driver per year showing total loads and rank
--   within that year. Tied drivers share the same rank and
--   the subsequent rank is skipped (e.g. 1, 2, 2, 4).
--
-- USE CASES:
--   Driver productivity benchmarking, annual performance
--   review, workload distribution analysis
-- ============================================================

WITH loads_per_driver AS (
    -- Aggregates total loads per driver per year
    SELECT
        drivers.driver_id,
        CONCAT(drivers.first_name, ' ', drivers.last_name) AS driver_name,
        YEAR(loads.load_date) AS `Year`,
        COUNT(loads.load_id) AS `Total Loads`
    FROM trips
    LEFT JOIN loads   ON trips.load_id   = loads.load_id
    LEFT JOIN drivers ON trips.driver_id = drivers.driver_id
    GROUP BY
        drivers.driver_id,
        drivers.first_name,
        drivers.last_name,
        YEAR(loads.load_date)
)

SELECT
    driver_id AS `Driver ID`,
    driver_name AS `Driver Name`,
    `Year`,
    `Total Loads`,
    RANK() OVER(PARTITION BY `Year` ORDER BY `Total Loads` DESC) AS `Driver Rank`  -- Resets per year; ties share the same rank
FROM loads_per_driver
ORDER BY `Year`, `Driver Rank`;
