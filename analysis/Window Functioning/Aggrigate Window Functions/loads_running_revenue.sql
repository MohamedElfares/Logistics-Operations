-- ============================================================
-- FILE: loads_running_revenue.sql
-- PURPOSE:
--   Calculates a cumulative running total of revenue across
--   all loads ordered by load date to track revenue growth
--   over time.
--
-- BUSINESS CONTEXT:
--   A running total transforms individual load revenue values
--   into a continuous growth curve. Rather than asking what
--   revenue was generated on a specific date, it answers how
--   much total revenue has been accumulated up to that point.
--   This is useful for tracking whether the business is
--   growing at a consistent pace, identifying periods of
--   acceleration or stagnation, and projecting forward from
--   any point in the timeline.
--
-- APPROACH:
--   SUM() is used as a window function with ORDER BY
--   load_date to accumulate revenue chronologically. No
--   PARTITION BY is applied — the accumulation is intentionally
--   global across all loads, reflecting total company revenue
--   growth rather than growth within a segment.
--
--   The frame clause is stated explicitly:
--     ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
--   This is the default behavior when ORDER BY is present,
--   but writing it explicitly documents the intent and avoids
--   ambiguity — particularly important when the query is
--   read alongside other window functions where the frame
--   clause matters significantly (LAST_VALUE, NTH_VALUE).
--
-- RESULT:
--   One row per load ordered by date, showing load details
--   alongside the cumulative revenue total up to and
--   including that load. The final row reflects total
--   revenue across the entire dataset.
--
-- USE CASES:
--   Revenue trend analysis, growth rate monitoring,
--   cumulative performance reporting
-- ============================================================

SELECT
    load_id,
    load_date,
    load_type,
    booking_type,
    weight_lbs,
    pieces,
    revenue,
    ROUND(
        SUM(revenue)
        OVER(
            ORDER BY load_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW -- Explicit frame: accumulates from first load to current row
        ), 2) AS `Running Revenue`
FROM loads
ORDER BY load_date;
