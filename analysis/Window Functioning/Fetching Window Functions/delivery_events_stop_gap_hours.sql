-- ============================================================
-- FILE: delivery_events_stop_gap_hours.sql
-- PURPOSE:
--   Calculates the planned time gap in hours between
--   consecutive delivery stops on the same load, using
--   the scheduled datetime of each event.
--
-- BUSINESS CONTEXT:
--   Multi-stop loads require realistic scheduling between
--   pickup and delivery events. A gap that is too short
--   relative to the distance between stops creates an
--   on-time delivery problem before the truck leaves the
--   dock. Surfacing this metric at the stop level supports
--   scheduling review and customer SLA compliance analysis.
--
-- APPROACH:
--   LEAD() retrieves the next row's scheduled datetime
--   within each load's event sequence, partitioned by
--   load_id and ordered by scheduled_datetime. Partitioning
--   by load_id ensures that LEAD() never crosses from one
--   load's last stop into the next load's first stop.
--
--   The gap is calculated using TIMESTAMPDIFF(MINUTE) divided
--   by 60 to produce decimal hours rather than truncated
--   whole hours. This preserves precision for gaps that
--   span partial hours.
--
--   The CASE expression handles the last stop of each load
--   explicitly — since LEAD() returns NULL when there is no
--   following row, the gap column is labeled 'Last Stop'
--   rather than displaying NULL, making the result cleaner
--   for reporting.
--
-- RESULT:
--   One row per delivery event showing scheduled arrival,
--   next stop arrival, and planned hours between stops.
--   The last stop on each load displays 'Last Stop' in
--   the gap column.
--
-- USE CASES:
--   Delivery scheduling analysis, SLA compliance review,
--   on-time performance root cause investigation
-- ============================================================

WITH scheduled_events AS (
    -- Retrieves each event's scheduled time and the next stop's scheduled time within the same load
    SELECT
        load_id,
        event_type,
        location_city,
        location_state,
        scheduled_datetime,
        LEAD(scheduled_datetime, 1)
            OVER(PARTITION BY load_id
                ORDER BY scheduled_datetime) AS next_stop_datetime  -- NULL on the last stop of each load
    FROM delivery_events
)

SELECT
    load_id AS `Load ID`,
    event_type AS `Event Type`,
    location_state AS `State`,
    location_city AS `City`,
    DATE_FORMAT(scheduled_datetime, '%Y-%m-%d %H:%i') AS `Scheduled Arrival`,
    DATE_FORMAT(next_stop_datetime, '%Y-%m-%d %H:%i') AS `Next Stop Arrival`,
    CASE
        WHEN next_stop_datetime IS NULL THEN 'Last Stop' -- No following stop; LEAD() returned NULL
        ELSE CAST(ROUND(TIMESTAMPDIFF(MINUTE, scheduled_datetime, next_stop_datetime) / 60, 2) AS CHAR)
    END AS `Hours Until Next Stop`  -- Decimal hours for precision
FROM scheduled_events
ORDER BY `Load ID`, `Scheduled Arrival`;
