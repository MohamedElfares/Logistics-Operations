-- ============================================================
-- FILE: fuel_purchases_trip_details.sql
-- PURPOSE:
--   Returns one row per fuel purchase enriched with the
--   driver's name, truck unit number, and trip dispatch date.
--
-- PROBLEM:
--   The fuel_purchases table stores transaction-level data —
--   gallons, price, and total cost — but only references
--   driver_id, truck_id, and trip_id as foreign keys. To
--   make the data readable, those IDs need to be resolved
--   to meaningful names and dates from their parent tables.
--
-- APPROACH:
--   fuel_purchases is used as the left (driving) table to
--   ensure every purchase appears in the result, even in
--   rare cases where the associated trip, driver, or truck
--   record is missing. Starting from trips instead would
--   silently exclude any purchases not linked to a valid trip.
--
--   All three joins are LEFT JOINs for the same reason —
--   a missing record on any side should not drop the
--   purchase row from the result.
--
-- RESULT:
--   One row per fuel purchase ordered by purchase date,
--   showing who bought the fuel, which truck was fueled,
--   when the trip was dispatched, and the full cost breakdown.
--
-- USE CASES:
--   Fuel spend auditing, driver fuel behavior analysis,
--   per-trip cost tracking
-- ============================================================

SELECT
    CONCAT(drivers.first_name, ' ', drivers.last_name) AS 'Driver Name',
    trucks.unit_number                                  AS 'Truck Unit Number',
    trips.dispatch_date                                 AS 'Dispatch Date',
    fuel_purchases.gallons                              AS 'Gallons',
    fuel_purchases.price_per_gallon                     AS 'Price/Gallon',
    fuel_purchases.total_cost                           AS 'Total Cost'
FROM fuel_purchases
LEFT JOIN trips   ON fuel_purchases.trip_id   = trips.trip_id      -- Resolves dispatch date
LEFT JOIN drivers ON fuel_purchases.driver_id = drivers.driver_id  -- Resolves driver name
LEFT JOIN trucks  ON fuel_purchases.truck_id  = trucks.truck_id    -- Resolves truck unit number
ORDER BY fuel_purchases.purchase_date;
