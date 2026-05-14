-- ============================================================
-- FILE: monthly_shipment_coverage.sql
-- PURPOSE:
--   Counts total shipments per month across the full date
--   range of the dataset to identify months with low or
--   zero load activity.
--
-- PROBLEM:
--   Querying the loads table directly only returns months
--   that have at least one record. Months with no shipments
--   simply do not appear — making it impossible to identify
--   gaps using a standard GROUP BY on load_date.
--
-- APPROACH:
--   A recursive CTE generates one row per month from the
--   earliest to the latest load date in the dataset. Both
--   endpoints are derived dynamically using MIN() and MAX()
--   on the loads table, so the series always covers the
--   exact date range without hardcoded values.
--
--   The generated series is then LEFT JOINed to the loads
--   table on both YEAR and MONTH to count shipments per
--   month. Joining on MONTH alone would cause cross-year
--   collisions — January 2022 would match January 2023
--   and 2024 simultaneously.
--
--   Months with zero loads return COUNT = 0 due to the
--   LEFT JOIN, making gaps immediately visible in the result.
--
-- RESULT:
--   One row per month across the full dataset range showing
--   the month label and total load count. Months with a
--   count of 0 indicate shipment gaps.
--
-- FINDING:
--   With ~85,000 trips across 3 years, all months in the
--   dataset are expected to have shipments. If this query
--   returns no zero-count months, it confirms continuous
--   operational coverage with no seasonal gaps in the data.
--
-- USE CASES:
--   Seasonal trend analysis, operational continuity review,
--   data completeness validation
-- ============================================================

WITH RECURSIVE date_series AS (
    -- Anchor: first month in the dataset (dynamic start point)
    SELECT (
        SELECT MIN(load_date)
        FROM loads
    ) AS series_date

    UNION ALL

    -- Recursive step: advance one month until the last load date
    SELECT series_date + INTERVAL 1 MONTH
    FROM date_series
    WHERE series_date < (
        SELECT MAX(load_date)
        FROM loads
    )
)

SELECT
    DATE_FORMAT(series_date, '%M %Y')   AS `Month`,
    COUNT(loads.load_id)                AS `Total Loads`  -- 0 = no shipments recorded for this month
FROM date_series
LEFT JOIN loads ON
    YEAR(series_date)  = YEAR(loads.load_date)  AND
    MONTH(series_date) = MONTH(loads.load_date)     -- Both conditions required to avoid cross-year collisions
GROUP BY series_date
ORDER BY series_date;
