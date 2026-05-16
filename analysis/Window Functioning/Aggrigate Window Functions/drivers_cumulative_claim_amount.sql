-- ============================================================
-- FILE: drivers_cumulative_claim_amount.sql
-- PURPOSE:
--   Computes the cumulative insurance claim amount per driver
--   ordered by incident date, showing total financial exposure
--   up to and including each recorded incident.
--
-- BUSINESS CONTEXT:
--   A single claim amount in isolation gives limited context.
--   Seeing the cumulative total up to each incident reveals
--   the full financial trajectory of a driver's safety record
--   — making it possible to identify at what point a driver's
--   cumulative exposure crossed a threshold that would warrant
--   intervention, reassignment, or insurance review. This is
--   more actionable than simply summing all claims at the end.
--
-- APPROACH:
--   SUM() is used as a window function partitioned by
--   driver_id so each driver's cumulative total is tracked
--   independently. ORDER BY incident_date ensures the
--   accumulation follows the chronological sequence of events.
--
--   The frame clause is stated explicitly:
--     ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
--   This is the default when ORDER BY is present, but is
--   written explicitly for clarity and consistency with
--   other window function queries in this project.
--
-- RESULT:
--   One row per incident showing the individual claim amount
--   and the running total of all claims for that driver up
--   to and including that incident. The final row per driver
--   reflects their total lifetime claim exposure.
--
-- USE CASES:
--   Driver risk exposure tracking, insurance cost analysis,
--   safety intervention threshold monitoring
-- ============================================================

SELECT
    safety_incidents.driver_id AS `Driver ID`,
    CONCAT(drivers.first_name, ' ', drivers.last_name) AS `Driver Name`,
    safety_incidents.incident_id AS `Incident ID`,
    safety_incidents.incident_date AS `Incident Date`,
    safety_incidents.location_city AS `City`,
    safety_incidents.location_state AS `State`,
    ROUND(safety_incidents.claim_amount, 2) AS `Claim Amount`,
    ROUND(
        SUM(safety_incidents.claim_amount)
        OVER(
            PARTITION BY safety_incidents.driver_id
            ORDER BY safety_incidents.incident_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW -- Explicit frame: accumulates from first incident to current row
        ), 2) AS `Cumulative Claim Amount`
FROM safety_incidents
LEFT JOIN drivers ON drivers.driver_id = safety_incidents.driver_id
ORDER BY safety_incidents.driver_id, safety_incidents.incident_date;
