-- ============================================================
-- FILE: customers_ranked_by_revenue_per_type.sql
-- PURPOSE:
--   Ranks customers by total revenue within each customer
--   type (Dedicated, Contract, Spot) using DENSE_RANK().
--
-- BUSINESS CONTEXT:
--   Customers are segmented into three types that reflect
--   different contract arrangements and pricing structures.
--   Ranking within each type rather than globally makes the
--   comparison meaningful — a Spot customer generating high
--   revenue is notable within that segment, but comparing
--   it directly against a Dedicated customer with a long-term
--   contract would be misleading.
--
-- APPROACH:
--   A CTE aggregates total revenue per customer from the
--   loads table. DENSE_RANK() is then applied in the outer
--   query, partitioned by customer_type so ranking resets
--   independently for each segment. DENSE_RANK() is chosen
--   over RANK() so that tied customers receive consecutive
--   ranks without gaps — rank 2 always follows rank 1
--   regardless of how many customers share rank 1.
--
-- RESULT:
--   One row per customer showing total revenue and rank
--   within their customer type. Customers with equal revenue
--   share the same rank and the next rank is not skipped.
--
-- USE CASES:
--   Customer profitability analysis within segments,
--   sales performance reporting, account prioritization
-- ============================================================

WITH customer_total_revenue AS (
    -- Aggregates total revenue per customer across all loads
    SELECT
        customers.customer_id,
        customers.customer_name,
        customers.customer_type,
        SUM(loads.revenue) AS total_revenue
    FROM customers
    LEFT JOIN loads ON loads.customer_id = customers.customer_id
    GROUP BY
        customer_id,
        customer_name,
        customer_type
)

SELECT
    customer_id AS `Customer ID`,
    customer_name AS `Customer Name`,
    customer_type AS `Customer Type`,
    ROUND(total_revenue, 2) AS `Total Revenue`,
    DENSE_RANK() OVER(
        PARTITION BY customer_type -- Ranking resets independently per customer type
        ORDER BY total_revenue DESC) AS `Customer Rank`
FROM customer_total_revenue
ORDER BY customer_type, `Customer Rank`;
