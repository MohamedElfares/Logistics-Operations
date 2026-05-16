-- ============================================================
-- FILE: trucks_3rd_most_expensive_fuel_purchase.sql
-- PURPOSE:
--   Applies NTH_VALUE() to retrieve the third most expensive
--   fuel purchase per truck and attach it to every row in
--   that truck's purchase history.
--
-- SKILL FOCUS:
--   This query is a targeted exercise in applying NTH_VALUE()
--   correctly, specifically to understand and resolve the
--   same default frame clause problem that affects LAST_VALUE().
--
--   By default, window functions use the frame:
--     RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
--
--   With this default, NTH_VALUE() can only see rows up to
--   the current row. For the first and second purchase rows,
--   the third value does not yet exist within the frame, so
--   NULL is returned even though the third most expensive
--   purchase exists in the partition. The function only
--   becomes visible from the third row onward.
--
--   The fix is the same as for LAST_VALUE():
--     ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
--
--   This extends the frame to the full partition, making the
--   third most expensive purchase visible on every row for
--   that truck regardless of the current row's position.
--
-- APPROACH:
--   The query starts from fuel_purchases and LEFT JOINs to
--   trucks to resolve unit number, make, and model year.
--   NTH_VALUE() is partitioned by truck_id and ordered by
--   total_cost descending so that position 3 corresponds
--   to the third highest cost purchase for each truck.
--
-- NOTE:
--   This is a skill-building exercise. Attaching the third
--   most expensive value to every row has limited standalone
--   analytical use. Its practical application would be in
--   a filtered context — for example, returning only the
--   row where total_cost equals the third most expensive
--   value, or using it as a threshold in a HAVING clause.
--
-- USE CASES:
--   Skill development — NTH_VALUE(), extended frame clauses,
--   understanding positional window function behavior
-- ============================================================

SELECT
    fuel_purchases.trip_id AS `Trip ID`,
    trucks.truck_id AS `Truck ID`,
    trucks.unit_number AS `Unit Number`,
    trucks.make AS `Make`,
    trucks.model_year AS `Model Year`,
    fuel_purchases.total_cost AS `Fuel Cost`,
    NTH_VALUE(fuel_purchases.total_cost, 3)
        OVER(
            PARTITION BY fuel_purchases.truck_id
            ORDER BY fuel_purchases.total_cost DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING  -- Overrides default frame; required for NTH_VALUE() to be visible on all rows
        ) AS `3rd Most Expensive`
FROM fuel_purchases
LEFT JOIN trucks ON trucks.truck_id = fuel_purchases.truck_id
ORDER BY trucks.truck_id, fuel_purchases.total_cost DESC;
