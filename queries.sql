SELECT
    trips.driver_id,
    DATE_FORMAT(trips.dispatch_date, '%Y-%m') AS month,
    COUNT(trips.trip_id) AS trips_completed,
    SUM(trips.actual_distance_miles) AS total_miles,
    ROUND(SUM(loads.revenue), 2) AS total_revenue,
    ROUND(AVG(trips.average_mpg), 2) AS average_mpg,
    ROUND(SUM(trips.fuel_gallons_used), 2) AS total_fuel_gallons,
    CONCAT(ROUND((SUM(on_time_flag) / COUNT(*)) * 100, 0), "%") AS `on_time_delivery (%)`,
    ROUND(AVG(idle_time_hours), 1) AS average_idle_hours

FROM trips
JOIN loads ON loads.load_id = trips.load_id
JOIN delivery_events ON delivery_events.trip_id = trips.trip_id
    WHERE delivery_events.event_type = 'Delivery'
GROUP BY
    trips.driver_id,
    month
ORDER BY driver_id
LIMIT 70;

SELECT
    trips.truck_id,
    DATE_FORMAT(trips.dispatch_date, '%Y-%m') AS month,
    COUNT(DISTINCT trips.trip_id) AS trips_completed,
    SUM(trips.actual_distance_miles) AS total_miles,
    ROUND(SUM(loads.revenue), 2) AS total_revenue,
    ROUND(AVG(trips.average_mpg), 2) AS average_mpg,
    ROUND(COALESCE(MAX(maintenance_records.maintenance_events), 0), 2) AS maintenance_events,
    ROUND(COALESCE(MAX(maintenance_records.maintenance_cost), 0), 2) AS maintenance_cost,
    ROUND(COALESCE(MAX(maintenance_records.downtime_hours), 0), 2) AS downtime_hours,
    ROUND(SUM(trips.actual_duration_hours) / (COUNT(trips.dispatch_date) * 24), 3) AS utilization_rate
FROM trips
JOIN loads ON loads.load_id = trips.load_id
LEFT JOIN (
    SELECT
        truck_id,
        DATE_FORMAT(maintenance_date, '%Y-%m') AS month,
        COUNT(*) AS maintenance_events,
        SUM(total_cost) AS maintenance_cost,
        SUM(downtime_hours) AS downtime_hours
    FROM `maintenance_records`
    GROUP BY
        truck_id,
        DATE_FORMAT(maintenance_date, '%Y-%m')
) maintenance_records
    ON maintenance_records.truck_id = trips.truck_id
    AND maintenance_records.month = DATE_FORMAT(trips.dispatch_date, '%Y-%m')
GROUP BY
    trips.truck_id,
    DATE_FORMAT(trips.dispatch_date, '%Y-%m')
ORDER BY trips.truck_id
LIMIT 20;
