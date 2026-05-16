-- ============================================================
-- FILE: drivers_rolling_avg_mpg.sql
-- PURPOSE:
--   Computes a 3-trip backward-looking rolling average of
--   MPG per driver to smooth out individual trip variation
--   and surface underlying fuel efficiency trends.
--
-- BUSINESS CONTEXT:
--   A single trip's MPG can be skewed by traffic, load
--   weight, idle time, or route terrain — none of which
--   reflect a driver's typical efficiency. A rolling average
--   smooths these one-off variations and makes it easier to
--   identify genuine improvement or decline in fuel efficiency
--   over time. Three trips is a common window size for
--   operational metrics — wide enough to smooth noise,
--   narrow enough to remain responsive to real changes.
--
-- APPROACH:
--   AVG() is used as a window function partitioned by
--   driver_id so each driver's rolling average is computed
--   independently. ORDER BY dispatch_date ensures the
--   average is calculated in chronological trip order.
--
--   The frame clause:
--     ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
--   includes the current trip and the two trips immediately
--   before it — a backward-looking 3-trip window. This is
--   the conventional direction for rolling averages in time
--   series analysis: the average reflects where the driver
--   has been, not where they are going.
--
--   For the first trip, only 1 row is in the frame.
--   For the second trip, only 2 rows are in the frame.
--   From the third trip onward, all 3 rows are included.
--   MySQL handles this automatically without requiring
--   a minimum frame size condition.
--
-- RESULT:
--   One row per trip showing individual MPG alongside the
--   3-trip rolling average. Comparing the two columns
--   reveals whether a given trip was above or below the
--   driver's recent efficiency baseline.
--
-- USE CASES:
--   Driver fuel efficiency trend analysis, coaching
--   identification, fleet performance monitoring
-- ============================================================

SELECT
    trips.load_id AS `Load ID`,
    drivers.driver_id AS `Driver ID`,
    CONCAT(drivers.first_name, ' ', drivers.last_name) AS `Driver Name`,
    trips.dispatch_date AS `Dispatch Date`,
    trips.actual_distance_miles AS `Distance (Miles)`,
    trips.fuel_gallons_used AS `Gallons`,
    ROUND(trips.average_mpg, 2) AS `Avg MPG`,
    ROUND(AVG(trips.average_mpg)
        OVER(
            PARTITION BY drivers.driver_id
            ORDER BY trips.dispatch_date
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW -- Backward-looking 3-trip window; shrinks for first two trips
        ), 2) AS `3-Trip Rolling Avg MPG`
FROM trips
LEFT JOIN drivers ON drivers.driver_id = trips.driver_id
ORDER BY drivers.driver_id, trips.dispatch_date;
