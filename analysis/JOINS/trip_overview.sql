-- ============================================================
-- FILE: trip_overview.sql
-- PURPOSE:
--   Provides a complete operational snapshot of every trip
--   by combining data from five related tables into one row.
--
-- BUSINESS CONTEXT:
--   The trips table is the central operational entity in the
--   schema. On its own it only holds IDs — driver_id, truck_id,
--   trailer_id, load_id. To make a trip record readable and
--   actionable, it must be joined to the surrounding tables
--   to surface names, equipment details, and customer context.
--
-- JOIN CHAIN:
--   trips
--     → drivers   (via trips.driver_id)
--     → trucks    (via trips.truck_id)
--     → trailers  (via trips.trailer_id)
--     → loads     (via trips.load_id)
--     → customers (via loads.customer_id)
--
--   Note: customers has no direct relationship to trips.
--   It is reached indirectly through loads, since a load
--   belongs to a customer and a trip carries a load.
--
-- RESULT:
--   One row per trip containing the driver's full name,
--   truck make, trailer type, and the customer who owns
--   the load — all in a single flat result set.
--
-- USE CASES:
--   Operational reporting, dispatch review, audit trails
-- ============================================================

SELECT
    trip_id,
    loads.load_id,
    CONCAT(drivers.first_name, ' ', drivers.last_name)  AS 'Driver',        -- Full name built from two columns
    trucks.make                                          AS 'Make',
    trailers.trailer_type                                AS 'Trailer Type',
    customers.customer_name                              AS 'Customer'
FROM trips
LEFT JOIN drivers   ON trips.driver_id   = drivers.driver_id    -- Driver assigned to the trip
LEFT JOIN trucks    ON trips.truck_id    = trucks.truck_id       -- Truck used for the trip
LEFT JOIN trailers  ON trips.trailer_id  = trailers.trailer_id  -- Trailer attached to the truck
LEFT JOIN loads     ON trips.load_id     = loads.load_id        -- Load carried on the trip
LEFT JOIN customers ON loads.customer_id = customers.customer_id -- Customer who owns the load
