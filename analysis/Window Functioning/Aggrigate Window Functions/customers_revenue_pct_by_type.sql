-- ============================================================
-- FILE: customers_revenue_pct_by_type.sql
-- PURPOSE:
--   Shows each customer's revenue as a percentage of the
--   total revenue generated within their customer type
--   (Dedicated, Contract, Spot).
--
-- BUSINESS CONTEXT:
--   Comparing customers globally by revenue can be
--   misleading when they operate under different contract
--   structures with different pricing and volume expectations.
--   A Spot customer and a Dedicated customer are not directly
--   comparable. Calculating revenue share within each type
--   instead surfaces which customers dominate their own
--   segment — a more meaningful measure of account
--   concentration and dependency risk.
--
-- APPROACH:
--   Two CTEs are used in sequence. The first aggregates
--   total revenue per customer from the loads table.
--   The second applies SUM() as a window function partitioned
--   by customer_type to compute the total revenue for each
--   type without collapsing rows — every customer row retains
--   its individual revenue while also carrying the type total
--   as a reference value.
--
--   The two CTEs are joined on customer_id in the outer
--   query so the percentage can be calculated by dividing
--   each customer's total by their type total directly.
--
--   This approach was chosen over computing the type total
--   inline in the outer SELECT to keep the percentage
--   calculation clean and readable — referencing named
--   aliases rather than repeating the full window expression.
--
-- RESULT:
--   One row per customer showing individual revenue, type
--   total revenue, and revenue share within their segment.
--   Ordered by customer type and percentage descending to
--   surface the dominant accounts within each segment first.
--
-- USE CASES:
--   Customer concentration analysis, segment revenue
--   distribution, account dependency risk assessment
-- ============================================================

WITH customer_revenue AS (
    -- Aggregates total revenue per customer across all loads
    SELECT
        customers.customer_id,
        customers.customer_name,
        customers.customer_type,
        customers.account_status,
        customers.annual_revenue_potential,
        SUM(loads.revenue)                          AS total_revenue
    FROM customers
    LEFT JOIN loads ON customers.customer_id = loads.customer_id
    GROUP BY
        customers.customer_id,
        customers.customer_name,
        customers.customer_type,
        customers.account_status,
        customers.annual_revenue_potential
),

customer_type_revenue AS (
    -- Computes total revenue per customer type using SUM() as a window function
    -- Partitioning by customer_type resets the sum for each segment independently
    SELECT
        customer_id,
        SUM(total_revenue) OVER (PARTITION BY customer_type) AS type_total_revenue
    FROM customer_revenue
)

SELECT
    customer_revenue.customer_id AS `Customer ID`,
    customer_revenue.customer_name AS `Customer Name`,
    customer_revenue.customer_type AS `Customer Type`,
    customer_revenue.account_status AS `Account Status`,
    customer_revenue.annual_revenue_potential AS `Annual Revenue Potential`,
    ROUND(total_revenue, 2) AS `Total Revenue`,
    ROUND(type_total_revenue, 2) AS `Type Total Revenue`, -- Denominator for the percentage calculation
    ROUND((total_revenue / type_total_revenue) * 100, 2) AS `Revenue % Within Type` -- Each customer's share of their segment total
FROM customer_revenue
LEFT JOIN customer_type_revenue ON
    customer_type_revenue.customer_id = customer_revenue.customer_id
ORDER BY customer_type, `Revenue % Within Type` DESC;
