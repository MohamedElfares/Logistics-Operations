-- ============================================================
-- FILE: drivers_first_dispatch_date.sql
-- PURPOSE:
--   Applies FIRST_VALUE() to attach each driver's earliest
--   dispatch date to every row in their trip history.
--
-- SKILL FOCUS:
--   This query is a targeted exercise in applying FIRST_VALUE()
--   with PARTITION BY and ORDER BY. It demonstrates how a
--   window function can carry a single reference value —
--   the first row in a partition — across all rows without
--   collapsing the result through aggregation.
--
--   The key distinction from MIN() with GROUP BY is that
--   FIRST_VALUE() preserves every trip row individually.
--   Each row retains its own dispatch date while also
--   carrying the partition's earliest date as a reference.
--
-- APPROACH:
--   The window is partitioned by driver_id so FIRST_VALUE()
--   finds the earliest dispatch date within each driver's
--   history independently. ORDER BY dispatch_date defines
--   what "first" means — the chronologically earliest trip.
--
--   TIMESTAMPDIFF(DAY) computes how many days have elapsed
--   since the driver's first trip, producing a simple tenure
--   metric on every row.
--
-- NOTE:
--   The query starts from drivers with a LEFT JOIN to trips,
--   meaning drivers with no trips appear with NULL values.
--   Starting from trips instead would exclude those rows.
--   The current structure was kept to practice the function
--   in its broader join context.
--
-- USE CASES:
--   Skill development — FIRST_VALUE(), window partitioning,
--   reference value attachment across partitioned rows
-- ============================================================

WITH earliest_dispatch_date AS (
    -- Attaches the first dispatch date in each driver's history to every trip row
    SELECT
        drivers.driver_id,
        trips.trip_id,
        trips.dispatch_date,
        FIRST_VALUE(trips.dispatch_date)
            OVER(PARTITION BY drivers.driver_id
                ORDER BY dispatch_date) AS first_dispatch_date  -- Repeats on every row for the same driver
    FROM drivers
    LEFT JOIN trips ON trips.driver_id = drivers.driver_id
)

SELECT
    driver_id AS `Driver ID`,
    trip_id AS `Trip ID`,
    dispatch_date AS `Dispatch Date`,
    first_dispatch_date AS `First Ever Dispatch`,
    TIMESTAMPDIFF(DAY, first_dispatch_date, dispatch_date) AS `Days Since First`  -- 0 on the first trip; grows with each subsequent trip
FROM earliest_dispatch_date
ORDER BY driver_id, dispatch_date;
