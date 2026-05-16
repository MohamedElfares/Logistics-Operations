-- ============================================================
-- FILE: drivers_trip_distance_lag.sql
-- PURPOSE:
--   Compares each driver's actual trip distance against their
--   immediately preceding trip to surface sudden changes in
--   route length.
--
-- BUSINESS CONTEXT:
--   A driver consistently running routes of similar length
--   who suddenly records a significantly longer or shorter
--   trip may indicate a detour, a routing error, an
--   unplanned stop, or a data entry issue. Identifying
--   these deviations at the individual trip level requires
--   row-to-row comparison, which standard aggregation
--   cannot produce.
--
-- APPROACH:
--   LAG() retrieves the previous row's distance within each
--   driver's trip sequence, partitioned by driver_id and
--   ordered by dispatch_date. The partition ensures that
--   the comparison is always within the same driver's
--   history — the last trip of one driver does not bleed
--   into the first trip of the next.
--
--   The CTE separates the LAG() computation from the final
--   SELECT so that the difference column can reference the
--   already-computed previous_miles alias directly, avoiding
--   repetition of the full window function expression.
--
--   ABS() is applied to the difference so the result always
--   represents the magnitude of change regardless of
--   direction. The first trip per driver returns NULL for
--   both previous_miles and miles_difference since there
--   is no prior row to compare against.
--
-- RESULT:
--   One row per trip showing origin, destination, current
--   distance, previous trip distance, and the absolute
--   difference. NULL values in the difference column
--   identify each driver's first recorded trip.
--
-- USE CASES:
--   Route deviation detection, driver behavior monitoring,
--   data quality auditing on trip distance records
-- ============================================================

WITH trip_distances AS (
    -- Joins trip, driver, and route data and computes the previous trip distance per driver
    SELECT
        trips.driver_id,
        trips.dispatch_date,
        CONCAT(drivers.first_name, ' ', drivers.last_name) AS driver_name,
        CONCAT(routes.origin_state, ' - ', routes.origin_city) AS origin_location,
        CONCAT(routes.destination_state, ' - ', routes.destination_city) AS destination_location,
        trips.actual_distance_miles AS miles,
        LAG(trips.actual_distance_miles, 1)
            OVER(PARTITION BY trips.driver_id ORDER BY dispatch_date) AS previous_miles  -- NULL on driver's first trip
    FROM trips
    LEFT JOIN drivers ON drivers.driver_id = trips.driver_id
    LEFT JOIN loads   ON loads.load_id     = trips.load_id
    LEFT JOIN routes  ON routes.route_id   = loads.route_id
)

SELECT
    driver_id AS `Driver ID`,
    driver_name AS `Driver Name`,
    dispatch_date AS `Dispatch Date`,
    origin_location AS `Origin`,
    destination_location AS `Destination`,
    miles AS `Miles`,
    previous_miles AS `Previous Miles`,
    ABS(miles - previous_miles) AS `Miles Difference`  -- Absolute magnitude; references CTE alias to avoid repeating LAG()
FROM trip_distances
ORDER BY driver_id, dispatch_date;
