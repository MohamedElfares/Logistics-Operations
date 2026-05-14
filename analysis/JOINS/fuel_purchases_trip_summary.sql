-- ============================================================
-- FILE: fuel_purchases_trip_summary.sql
-- PURPOSE:
--   Aggregates all fuel purchases per trip into a single
--   summary row showing average and total fuel metrics.
--
-- DIFFERENCE FROM fuel_purchases_trip_details.sql:
--   The details file returns one row per purchase transaction.
--   This file collapses all purchases for a given trip into
--   one row — useful when the unit of analysis is the trip,
--   not the individual transaction.
--
-- APPROACH:
--   trips is the left (driving) table since the goal is a
--   trip-level summary. fuel_purchases is joined on trip_id
--   and aggregated with AVG() and SUM(). The WHERE clause
--   filters out trips with no fuel records before grouping,
--   which effectively converts the LEFT JOIN to an INNER JOIN
--   for this specific query — only trips with at least one
--   fuel purchase are included in the result.
--
--   Note: trucks.unit_number is included in the SELECT but
--   not in the GROUP BY, which will raise an error under
--   MySQL's ONLY_FULL_GROUP_BY mode. It should be added to
--   the GROUP BY or wrapped in ANY_VALUE() if needed.
--
-- RESULT:
--   One aggregated row per trip showing the driver, truck,
--   dispatch date, average gallons per fill-up, average
--   price per gallon, and total fuel cost for the trip.
--
-- USE CASES:
--   Per-trip fuel cost analysis, driver fuel efficiency
--   comparison, fleet cost reporting
-- ============================================================

SELECT
    trips.trip_id,
    drivers.driver_id,
    CONCAT(drivers.first_name, ' ', drivers.last_name)  AS 'Driver Name',
    trucks.unit_number                                   AS 'Truck Unit Num',
    trips.dispatch_date                                  AS 'Dispatch Date',
    ROUND(AVG(fuel_purchases.gallons), 2)                AS 'Avg Gallons',       -- Average per fill-up on this trip
    ROUND(AVG(fuel_purchases.price_per_gallon), 2)       AS 'AVG Price/Gallon',
    ROUND(SUM(fuel_purchases.total_cost), 2)             AS 'Total Cost'         -- Total fuel spend for the trip
FROM trips
LEFT JOIN drivers        ON trips.driver_id  = drivers.driver_id
LEFT JOIN trucks         ON trips.truck_id   = trucks.truck_id
LEFT JOIN fuel_purchases ON trips.trip_id    = fuel_purchases.trip_id
WHERE fuel_purchases.gallons IS NOT NULL    -- Excludes trips with no fuel records
GROUP BY
    trips.trip_id,
    drivers.driver_id,
    trips.dispatch_date
ORDER BY trip_id;
