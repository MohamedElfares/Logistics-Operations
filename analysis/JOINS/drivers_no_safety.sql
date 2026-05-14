-- ============================================================
-- FILE: drivers_no_safety_incidents.sql
-- PURPOSE:
--   Identifies drivers who have never been involved in a
--   recorded safety incident, limited to those who have
--   actually been dispatched on at least one trip.
--
-- PROBLEM:
--   A simple LEFT JOIN from drivers to safety_incidents with
--   an IS NULL filter correctly finds drivers with no incident
--   records. However, this would also include drivers who
--   have never been dispatched at all — drivers with zero
--   trips would appear as "safe" purely because they have
--   never been on the road. That result would be misleading.
--
-- APPROACH:
--   Two LEFT JOINs are applied:
--     1. drivers → safety_incidents: to find drivers with no
--        incident record (WHERE IS NULL)
--     2. drivers → trips: to count how many trips each driver
--        has completed
--
--   The HAVING clause then filters out drivers with zero trips,
--   ensuring the result only contains drivers with a genuine
--   clean safety record backed by actual operational activity.
--
-- RESULT:
--   A list of active and terminated drivers who have completed
--   at least one trip and have no associated safety incident.
--   Total Trips provides context for how much road exposure
--   each driver has had without an incident.
--
-- USE CASES:
--   Safety performance recognition, driver risk profiling,
--   insurance reporting
-- ============================================================

SELECT
    drivers.driver_id                                       AS 'ID',
    CONCAT(drivers.first_name, ' ', drivers.last_name)     AS 'Driver Name',
    drivers.license_state                                   AS 'License State',
    drivers.employment_status                               AS 'Status',
    drivers.year_experience                                 AS 'Experience (Years)',
    COUNT(trips.trip_id)                                    AS 'Total Trips'  -- Road exposure without an incident
FROM drivers
LEFT JOIN safety_incidents  ON drivers.driver_id = safety_incidents.driver_id
LEFT JOIN trips             ON drivers.driver_id = trips.driver_id
WHERE safety_incidents.driver_id IS NULL    -- No matching record in safety_incidents
GROUP BY
    drivers.driver_id,
    drivers.first_name,
    drivers.last_name,
    drivers.license_state,
    drivers.employment_status,
    drivers.year_experience
HAVING COUNT(trips.trip_id) != 0            -- Excludes drivers who have never been dispatched
ORDER BY drivers.driver_id;
