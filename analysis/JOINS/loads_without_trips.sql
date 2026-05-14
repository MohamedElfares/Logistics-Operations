-- ============================================================
-- FILE: loads_without_trips.sql
-- PURPOSE:
--   Identifies loads that were booked into the system but
--   never assigned to a trip — meaning they were never
--   physically dispatched.
--
-- PROBLEM:
--   Not every load in the loads table has a corresponding
--   trip record. A load can be created when a customer books
--   a shipment, but a trip is only created when a driver,
--   truck, and trailer are assigned and the load is dispatched.
--   Loads that fall through this gap are invisible in any
--   query that starts from the trips table.
--
-- APPROACH:
--   A LEFT JOIN from loads to trips keeps all load records
--   regardless of whether a matching trip exists. When no
--   trip is found, trips columns return NULL. Filtering on
--   WHERE trips.load_id IS NULL isolates exactly those loads
--   that have no dispatch record.
--
--   Important: placing a condition on the right-side table
--   in the WHERE clause (rather than the ON clause) turns a
--   LEFT JOIN into an INNER JOIN. The IS NULL filter is the
--   correct exception — it specifically targets unmatched rows.
--
-- RESULT:
--   A list of unmatched loads with their booking details and
--   customer name. The load_status column is particularly
--   useful here — a load marked 'Completed' with no trip
--   record is a data integrity issue worth investigating.
--
-- USE CASES:
--   Dispatch gap analysis, data quality auditing,
--   customer billing review
-- ============================================================

SELECT
    loads.load_id,
    loads.load_date     AS 'Load Date',
    loads.load_type     AS 'Type',
    loads.load_status   AS 'Status',      -- Flag: 'Completed' with no trip = potential data issue
    loads.booking_type  AS 'Booking Type',
    customers.customer_name AS 'Customer Name'
FROM loads
LEFT JOIN customers ON customers.customer_id = loads.customer_id
LEFT JOIN trips     ON trips.load_id         = loads.load_id
WHERE trips.load_id IS NULL   -- Retains only loads with no matching trip record
ORDER BY loads.load_id;
