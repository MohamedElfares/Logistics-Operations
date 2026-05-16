-- ============================================================
-- FILE: drivers_mpg_quartiles.sql
-- PURPOSE:
--   Segments drivers into four fuel efficiency performance
--   tiers based on average MPG across all completed trips.
--
-- BUSINESS CONTEXT:
--   Fuel is one of the largest variable costs in fleet
--   operations. Identifying which drivers consistently
--   achieve higher MPG versus those in the bottom quartile
--   supports decisions around driver coaching, route
--   assignment, and fuel cost reduction initiatives.
--   Quartile-based segmentation is more actionable than
--   a raw ranking because it groups drivers into tiers
--   that can be targeted with different interventions.
--
-- APPROACH:
--   A CTE aggregates total trips and average MPG per driver.
--   Employment status and years of experience are included
--   to support correlation analysis — for example, whether
--   low MPG quartiles skew toward newer or terminated drivers.
--
--   NTILE(4) divides all drivers into four equal-sized
--   buckets ordered by average MPG descending, so quartile 1
--   always contains the most fuel-efficient drivers.
--   A CASE expression translates the numeric quartile into
--   a readable performance label.
--
--   Note: NTILE(4) is called twice in the SELECT — once for
--   the numeric quartile and once for the label. MySQL does
--   not allow referencing a window function alias in the same
--   SELECT clause, making the repetition necessary here.
--
-- RESULT:
--   One row per driver showing average MPG, quartile number,
--   and performance label. Drivers within the same quartile
--   are ordered by MPG descending.
--
-- USE CASES:
--   Fuel efficiency benchmarking, driver coaching targeting,
--   fleet cost reduction analysis
-- ============================================================

WITH driver_performance AS (
    -- Aggregates trip count and average MPG per driver
    SELECT
        drivers.driver_id,
        CONCAT(drivers.first_name, ' ', drivers.last_name) AS driver_name,
        drivers.employment_status AS `status`,
        drivers.year_experience AS experience,
        COUNT(trips.trip_id) AS total_trips,
        AVG(trips.average_mpg) AS avg_mpg
    FROM trips
    LEFT JOIN drivers ON drivers.driver_id = trips.driver_id
    GROUP BY
        drivers.driver_id,
        drivers.first_name,
        drivers.last_name,
        drivers.employment_status,
        drivers.year_experience
)

SELECT
    driver_id AS `Driver ID`,
    driver_name AS `Driver Name`,
    `status` AS `Status`,
    experience AS `Experience (Years)`,
    total_trips AS `Total Trips`,
    ROUND(avg_mpg, 2) AS `Avg MPG`,
    NTILE(4) OVER(ORDER BY avg_mpg DESC) AS `MPG Quartile`,       -- 1 = highest MPG, 4 = lowest MPG
    CASE NTILE(4) OVER(ORDER BY avg_mpg DESC)
        WHEN 1 THEN 'Top Performers'
        WHEN 2 THEN 'Above Average'
        WHEN 3 THEN 'Below Average'
        WHEN 4 THEN 'Low Performers'
    END AS `Quartile Label`      -- Human-readable performance tier
FROM driver_performance
ORDER BY `MPG Quartile`, `Avg MPG` DESC;
