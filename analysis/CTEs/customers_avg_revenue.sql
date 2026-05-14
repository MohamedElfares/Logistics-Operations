-- ============================================================
-- FILE: customers_above_avg_revenue.sql
-- PURPOSE:
--   Identifies customers whose annual revenue exceeds the
--   overall average annual revenue across all customers.
--
-- APPROACH:
--   Two CTEs are used in sequence:
--
--   CTE 1 — revenue_per_customer:
--     Aggregates total revenue and average revenue per load
--     for each customer, broken down by year. This produces
--     one row per customer per year.
--
--   CTE 2 — overall_avg:
--     Computes the average of all customers' annual totals
--     from CTE 1. This always returns exactly one row —
--     a single overall benchmark value.
--
--   The two CTEs are combined using CROSS JOIN. Since
--   overall_avg is a single row, the cross join simply
--   attaches the benchmark value to every row in
--   revenue_per_customer without creating duplicates.
--   This allows the WHERE clause to compare each customer's
--   annual revenue directly against the overall average
--   in a single, readable query.
--
-- RESULT:
--   Customers and years where annual revenue exceeded the
--   overall average, ordered by customer name and year.
--   The Overall Average column is included in every row
--   as a reference point for the comparison.
--
-- USE CASES:
--   High-value customer identification, sales performance
--   analysis, revenue segmentation reporting
-- ============================================================

WITH revenue_per_customer AS (
    -- Annual revenue per customer, grouped by year
    SELECT
        customers.customer_name             AS `Name`,
        customers.customer_type             AS `Type`,
        customers.primary_freight_type      AS `Freight Type`,
        customers.account_status            AS `Account Status`,
        YEAR(loads.load_date)               AS `Year`,
        SUM(loads.revenue)                  AS `Total Revenue`,
        AVG(loads.revenue)                  AS `Avg Revenue Per Load`  -- Average per individual load, not per year
    FROM customers
    LEFT JOIN loads ON loads.customer_id = customers.customer_id
    GROUP BY
        customers.customer_name,
        customers.customer_type,
        customers.primary_freight_type,
        customers.account_status,
        YEAR(loads.load_date)
),

overall_avg AS (
    -- Single-row benchmark: average of all customers' annual revenue totals
    SELECT AVG(`Total Revenue`) AS `Overall Average`
    FROM revenue_per_customer
)

SELECT
    `Name`,
    `Type`,
    `Freight Type`,
    `Account Status`,
    `Year`,
    ROUND(`Total Revenue`, 2)           AS `Total Revenue`,
    ROUND(`Avg Revenue Per Load`, 2)    AS `Avg Revenue Per Load`,
    ROUND(`Overall Average`, 2)         AS `Overall Average`       -- Benchmark shown for reference
FROM revenue_per_customer
CROSS JOIN overall_avg                          -- Attaches the single benchmark row to every customer row
WHERE `Total Revenue` > `Overall Average`       -- Filters to above-average customers only
ORDER BY `Name`, `Year`;
