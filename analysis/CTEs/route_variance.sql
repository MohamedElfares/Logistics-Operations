-- ============================================================
-- FILE: drivers_route_distance_variance.sql
-- PURPOSE:
--   Classifies each trip by how much the actual distance
--   deviated from the expected route distance, then
--   summarizes variance categories per driver.
--
-- PROBLEM:
--   Each route in the routes table has a typical_distance_miles
--   value representing the expected distance for that corridor.
--   Trips where drivers significantly deviate from this
--   expectation — either over or under — may indicate
--   route inefficiency, unauthorized detours, or data issues.
--
-- THRESHOLD ANALYSIS:
--   The original threshold of 10% over route was applied
--   first. The query returned 100% of drivers as 'On Route',
--   meaning no trip exceeded 110% of the typical distance.
--
--   A ratio analysis was run to understand the actual
--   distribution of variance in the dataset:
--
--     MIN ratio : 0.9760  (2.4% below typical)
--     MAX ratio : 1.0799  (7.99% above typical)
--     AVG ratio : 1.0291  (2.9% above typical on average)
--
--   This confirmed that the synthetic dataset constrains
--   actual distance to within roughly ±8% of typical distance.
--   The 10% threshold was therefore adjusted to 5% over and
--   1% under to produce a meaningful three-category split.
--
-- APPROACH:
--   A CTE joins trips to routes through loads (since the
--   route is assigned at the load level, not the trip level)
--   and applies a CASE expression to assign each trip one
--   of three variance labels. The outer query groups by
--   driver and counts each category, expressing results
--   as both counts and percentages.
--
-- RESULT:
--   One row per driver showing total trips and the count
--   and percentage of Over Route, Under Route, and On Route
--   trips. The three percentages sum to 100% per driver.
--
-- NOTE ON DATASET LIMITATION:
--   The narrow variance range (max 7.99% above typical)
--   is a characteristic of the synthetic data generation
--   process. In real operational data, deviations above
--   10% would be expected and the original threshold
--   would be appropriate.
--
-- USE CASES:
--   Route compliance monitoring, driver behavior analysis,
--   operational efficiency reporting
-- ============================================================

WITH flag_trips AS (
    -- Assigns a variance label to each trip based on distance deviation
    SELECT
        trips.trip_id,
        routes.route_id,
        trips.driver_id,
        trips.dispatch_date,
        trips.actual_distance_miles,
        routes.typical_distance_miles,
        CASE
            WHEN trips.actual_distance_miles >= 1.05 * routes.typical_distance_miles THEN 'Over Route'   -- >5% above expected
            WHEN trips.actual_distance_miles <= 0.99 * routes.typical_distance_miles THEN 'Under Route'  -- >1% below expected
            ELSE 'On Route'
        END AS route_distance_variance
    FROM trips
    LEFT JOIN loads  ON trips.load_id    = loads.load_id       -- Route is assigned at the load level
    LEFT JOIN routes ON routes.route_id  = loads.route_id
)

SELECT
    driver_id                                                                                                           AS `Driver ID`,
    COUNT(trip_id)                                                                                                      AS `Trips`,
    COUNT(CASE WHEN route_distance_variance = 'Over Route'  THEN 1 END)                                                AS `Over Route`,
    CONCAT(ROUND(COUNT(CASE WHEN route_distance_variance = 'Over Route'  THEN 1 END) / COUNT(trip_id) * 100, 2), ' %') AS `Over Route %`,
    COUNT(CASE WHEN route_distance_variance = 'Under Route' THEN 1 END)                                                AS `Under Route`,
    CONCAT(ROUND(COUNT(CASE WHEN route_distance_variance = 'Under Route' THEN 1 END) / COUNT(trip_id) * 100, 2), ' %') AS `Under Route %`,
    COUNT(CASE WHEN route_distance_variance = 'On Route'    THEN 1 END)                                                AS `On Route`,
    CONCAT(ROUND(COUNT(CASE WHEN route_distance_variance = 'On Route'    THEN 1 END) / COUNT(trip_id) * 100, 2), ' %') AS `On Route %`
FROM flag_trips
GROUP BY driver_id
ORDER BY driver_id;
