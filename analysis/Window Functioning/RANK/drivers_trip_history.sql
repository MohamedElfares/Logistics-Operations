-- ============================================================
-- FILE: drivers_trip_history.sql
-- PURPOSE:
--   Assigns a sequential trip number to each trip per driver
--   ordered chronologically by dispatch date, building a
--   personal trip history for each driver.
--
-- BUSINESS CONTEXT:
--   Knowing the sequence of trips a driver has completed
--   enables tenure-based analysis — comparing early-career
--   trips against later ones, or identifying at which point
--   in a driver's history incidents or performance changes
--   occurred. A sequential number makes that reference point
--   explicit on every row.
--
-- APPROACH:
--   ROW_NUMBER() is used instead of RANK() or DENSE_RANK()
--   because the goal is a strict sequential number with no
--   ties. Even if two trips share the same dispatch date,
--   each must receive a unique trip number. ROW_NUMBER()
--   guarantees this — the ordering between tied rows is
--   arbitrary but the sequence is never broken.
--
--   PARTITION BY driver_id resets the counter for each
--   driver so that every driver's history starts at 1
--   independently of all other drivers.
--
-- RESULT:
--   One row per trip showing the driver, sequential trip
--   number, dispatch date, and trip ID. The sequence starts
--   at 1 for each driver's earliest dispatched trip.
--
-- USE CASES:
--   Driver tenure analysis, trip sequence auditing,
--   early vs late career performance comparison
-- ============================================================

WITH drivers_history AS (
    -- Joins trip records with driver name for readability
    SELECT
        trips.driver_id,
        CONCAT(drivers.first_name, ' ', drivers.last_name) AS driver_name,
        trips.dispatch_date,
        trips.trip_id
    FROM trips
    LEFT JOIN drivers ON drivers.driver_id = trips.driver_id
)

SELECT
    driver_id AS `Driver ID`,
    driver_name AS `Driver Name`,
    ROW_NUMBER() OVER(PARTITION BY driver_id ORDER BY dispatch_date) AS `Trip #`,  -- Unique sequence per driver, resets at 1
    dispatch_date AS `Dispatch Date`,
    trip_id AS `Trip ID`
FROM drivers_history
ORDER BY driver_id, dispatch_date;
