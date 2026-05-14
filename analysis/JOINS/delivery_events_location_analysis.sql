-- ============================================================
-- FILE: delivery_events_location_analysis.sql
-- PURPOSE:
--   Investigates the relationship between location_city in
--   delivery_events and city in facilities, and documents
--   findings about what location_city actually represents.
--
-- FINDING:
--   location_city in delivery_events does NOT represent the
--   facility's city. It represents the shipment's city derived
--   from the route:
--     - Pickup events   → location_city matches routes.origin_city
--     - Delivery events → location_city matches routes.destination_city
--
--   facility_id and location_city serve two different purposes:
--     - facility_id   → where the event was operationally processed
--     - location_city → where the freight was physically moving to/from
--
--   The 3.45% of cases where facility city and location_city match
--   are routes where the processing facility happens to be located
--   in the same city as the shipment origin or destination —
--   not returns or special cases.
-- ============================================================


-- ============================================================
-- STEP 1: Measure the overall mismatch between facility city
--         and event location city across all events.
--
-- Result: 96.55% mismatch confirmed that location_city is NOT
--         derived from the facility record.
-- ============================================================
SELECT
    COUNT(*)                                                                                                     AS 'Total Events',
    SUM(CASE WHEN facilities.city = delivery_events.location_city THEN 1 ELSE 0 END)                             AS 'Matching',
    SUM(CASE WHEN facilities.city != delivery_events.location_city THEN 1 ELSE 0 END)                            AS 'Mismatching',
    ROUND(SUM(CASE WHEN facilities.city != delivery_events.location_city THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS 'Mismatch %'
FROM delivery_events
LEFT JOIN facilities ON delivery_events.facility_id = facilities.facility_id;


-- ============================================================
-- STEP 2: Break down the mismatch by event type (Pickup vs Delivery)
--         to check whether matches concentrate in one event type,
--         which would support the route-based location hypothesis.
-- ============================================================
SELECT
    delivery_events.event_type                                                                                  AS 'Event Type',
    COUNT(*)                                                                                                    AS 'Total Events',
    SUM(CASE WHEN facilities.city = delivery_events.location_city THEN 1 ELSE 0 END)                            AS 'Matching',
    ROUND(SUM(CASE WHEN facilities.city = delivery_events.location_city THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS 'Match %'
FROM delivery_events
LEFT JOIN facilities ON delivery_events.facility_id = facilities.facility_id
GROUP BY delivery_events.event_type;


-- ============================================================
-- STEP 3: Confirm the hypothesis by joining to routes through loads.
--
-- For Delivery events: location_city matches routes.destination_city
-- For Pickup events:   location_city matches routes.origin_city
--
-- Switch the WHERE clause between 'Delivery' and 'Pickup' to
-- verify both directions of the finding.
-- ============================================================
SELECT
    delivery_events.event_id   AS 'Event ID',
    delivery_events.event_type AS 'Event Type',

    -- Facility information (operational processing location)
    facilities.facility_name AS 'Facility Name',
    facilities.facility_type AS 'Facility Type',
    facilities.city          AS 'Facility City',

    -- Shipment location (derived from route, not from facility)
    delivery_events.location_city AS 'Event City',

    -- Route endpoints for comparison
    -- Pickup events:   Event City should match Origin City
    -- Delivery events: Event City should match Destination City
    routes.origin_city      AS 'Origin City',
    routes.destination_city AS 'Destination City',

    -- Flag whether the facility city and event city align
    -- Expected to be 'Mismatch' in ~96.55% of rows
    CASE
        WHEN facilities.city = delivery_events.location_city THEN 'Match'
        ELSE 'Mismatch'
    END AS 'Facility vs Event City'

FROM delivery_events
LEFT JOIN facilities ON delivery_events.facility_id = facilities.facility_id
LEFT JOIN loads ON delivery_events.load_id = loads.load_id
LEFT JOIN routes ON loads.route_id = routes.route_id

-- Switch to 'Pickup' to verify location_city matches origin_city
WHERE delivery_events.event_type = 'Delivery'

ORDER BY delivery_events.event_id;