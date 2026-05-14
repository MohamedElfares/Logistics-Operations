-- ============================================================
-- FILE: 03_optimization.sql
-- PURPOSE:
--   Creates analytical views and performance indexes for the
--   logistics database. Views expose pre-joined, aggregated
--   datasets that support reporting and business intelligence
--   without modifying the underlying tables.
--
-- DEPENDENCIES:
--   Must be executed after 02_schema.sql and after data
--   has been loaded via 04_load_data.sql.
--
-- SECTIONS:
--   1. Analytical Views
--   2. Performance Indexes
-- ============================================================

USE `logistics`;


-- ============================================================
-- SECTION 1: ANALYTICAL VIEWS
-- ============================================================

-- =========================================================
-- View: vw_customer_performance
-- Purpose:
--   Provides a summarized performance overview per customer.
--
-- Description:
--   - Counts total loads handled per customer
--   - Calculates total and average revenue
--   - Includes all customers via LEFT JOIN, even those
--     with no associated loads
--
-- Use Cases:
--   Customer profitability analysis, sales reporting,
--   identifying high-value accounts
-- =========================================================
CREATE OR REPLACE VIEW `vw_customer_performance` AS
	SELECT
		customers.`customer_id`,
		`customer_name`,
		`customer_type`,
		COUNT(`load_id`) AS `total loads`,
		ROUND(SUM(`revenue`), 2) AS `total revenue`,
		ROUND(AVG(`revenue`), 2) AS `avg revenue`
	
	FROM customers
	LEFT JOIN loads ON customers.customer_id = loads.customer_id
	GROUP BY customers.`customer_id`;


-- =========================================================
-- View: vw_driver_performance
-- Purpose:
--   Tracks yearly productivity and fuel efficiency per driver.
--
-- Description:
--   - Aggregates total loads and miles driven per year
--   - Computes average MPG per year
--   - Excludes records with missing dispatch dates
--
-- Use Cases:
--   Driver performance evaluation, productivity reporting,
--   fuel efficiency monitoring
-- =========================================================
CREATE OR REPLACE VIEW `vw_driver_performance` AS
	SELECT
		drivers.`driver_id`,
		CONCAT(`first_name`, ' ', `last_name`) AS `driver name`,
		YEAR(`dispatch_date`) AS `year`,
		COUNT(`load_id`) AS `total loads`,
		COALESCE(ROUND(SUM(`actual_distance_miles`), 2), 0) AS `total miles`,
		COALESCE(ROUND(AVG(`average_mpg`), 2), 0) AS `avg mpg`
	
	FROM drivers
	LEFT JOIN trips ON drivers.driver_id = trips.driver_id
	WHERE YEAR(`dispatch_date`) IS NOT NULL
	GROUP BY drivers.`driver_id`, YEAR(`dispatch_date`)
	ORDER BY driver_id;


-- =========================================================
-- View: vw_delivery_performance
-- Purpose:
--   Measures on-time delivery performance per driver by year.
--
-- Description:
--   - Counts total delivery stops and on-time stops
--   - Computes on-time delivery percentage as a KPI
--
-- Use Cases:
--   Service level monitoring, driver KPI tracking,
--   operational performance dashboards
-- =========================================================
CREATE OR REPLACE VIEW `vw_delivery_performance` AS
	SELECT
		drivers.`driver_id`,
		CONCAT(`first_name`, " ", `last_name`) AS `driver name`,
		YEAR(`scheduled_datetime`) AS `year`,
		COUNT(*) AS `total stops`,
		COALESCE(SUM(`on_time_flag`), 0) AS `on_time stops`,
		CASE 
			WHEN COUNT(*) > 0 
			THEN ROUND((COALESCE(SUM(`on_time_flag`), 0) / COUNT(*) * 100), 2)
			ELSE 0 
		END AS `on_time percent`
	
	FROM trips
	LEFT JOIN delivery_events ON delivery_events.load_id = trips.load_id
	LEFT JOIN drivers ON drivers.driver_id = trips.driver_id
	GROUP BY drivers.`driver_id`, YEAR(`scheduled_datetime`)
	ORDER BY driver_id;


-- =========================================================
-- View: vw_fuel_efficiency
-- Purpose:
--   Provides annual fuel consumption and cost analytics
--   aggregated by truck.
--
-- Description:
--   - Summarizes total gallons consumed and total fuel cost
--   - Calculates average price per gallon per year
--   - Includes each truck's tank capacity for context
--
-- Use Cases:
--   Fuel cost analysis, fleet efficiency monitoring,
--   annual budget planning
-- =========================================================
CREATE OR REPLACE VIEW `vw_fuel_efficiency` AS
	SELECT
		fuel_purchases.`truck_id`,
		`tank_capacity_gallons` AS `tank_capacity`,
		YEAR(`purchase_date`) as `year`,
		ROUND(SUM(`gallons`), 2) AS `total_gallons`,
		ROUND(SUM(`total_cost`), 2) AS `total_fuel_cost`,
		ROUND(AVG(`price_per_gallon`), 2) AS `avg_price`
	FROM fuel_purchases
	LEFT JOIN trucks ON trucks.truck_id = fuel_purchases.truck_id
	GROUP BY truck_id, YEAR(`purchase_date`)
	ORDER BY truck_id;


-- =========================================================
-- View: vw_truck_maintenance_cost
-- Purpose:
--   Analyzes safety incidents and associated vehicle damage
--   costs, grouped by driver, truck, and year.
--
-- Description:
--   - Counts total incidents per driver per year
--   - Calculates average vehicle damage cost per incident
--   - Concatenates incident descriptions for review
--
-- Use Cases:
--   Risk management reporting, safety performance tracking,
--   identifying high-risk drivers or vehicles
-- =========================================================
CREATE OR REPLACE VIEW `vw_truck_maintenance_cost` AS
	SELECT
		safety_incidents.driver_id,
		CONCAT(drivers.first_name, ' ', drivers.last_name) AS `driver_name`,
		YEAR(incident_date) AS `year`,
		COUNT(*) AS `incidents`,
		ROUND(AVG(vehicle_damage_cost), 2) AS `avg_cost`,
		GROUP_CONCAT(description SEPARATOR ' | ') AS `incidents description`
		
	FROM safety_incidents
	LEFT JOIN drivers ON drivers.driver_id = safety_incidents.driver_id
	GROUP BY safety_incidents.driver_id, YEAR(incident_date)
	ORDER BY driver_id;


-- =========================================================
-- View: vw_customer_loads
-- Purpose:
--   Provides detailed load-level information per customer.
--
-- Description:
--   - Lists all loads associated with each customer
--   - Includes load type, weight, and revenue
--   - Combines fuel surcharge and accessorial charges
--     into a single charges column
--
-- Use Cases:
--   Customer billing review, load history reporting,
--   revenue breakdown analysis
-- =========================================================
CREATE OR REPLACE VIEW `vw_customer_loads` AS
	SELECT
		customers.customer_id,
		customer_name,
		customer_type,
		load_date,
		load_type,
		weight_lbs,
		revenue,
		ROUND((fuel_surcharge + accessorial_charges), 2) AS charges
	FROM customers
	LEFT JOIN loads ON customers.customer_id = loads.customer_id;


-- =========================================================
-- View: vw_driver_loads
-- Purpose:
--   Provides comprehensive trip and load details per driver.
--
-- Description:
--   - Joins driver, truck, trailer, and load data
--   - Exposes trip metrics: distance, duration, idle time
--   - Useful for operational tracking and auditing
--
-- Use Cases:
--   Driver activity reports, fleet utilization analysis,
--   operational monitoring
-- =========================================================
CREATE OR REPLACE VIEW `vw_driver_loads` AS
	SELECT
		drivers.driver_id,
		CONCAT(drivers.first_name, ' ', drivers.last_name) AS driver_name,
		drivers.license_number AS driver_license,
		drivers.license_state AS license_state,
		trucks.unit_number AS truck_number,
		trucks.vin AS truck_vin,
		trailers.trailer_number AS trailer_number,
		trailers.vin AS trailer_vin,
		trips.actual_distance_miles AS `distance(mi)`,
		trips.actual_duration_hours AS `duration(h)`,
		trips.idle_time_hours AS `idle_time(h)`,
		trips.trip_status AS trip_status,
		loads.load_type,
		loads.pieces AS `load_pieces`

		FROM trips
		LEFT JOIN drivers ON drivers.driver_id = trips.driver_id
		LEFT JOIN trucks ON trucks.truck_id = trips.truck_id
		LEFT JOIN trailers ON trailers.trailer_id = trips.trailer_id
		LEFT JOIN loads ON loads.load_id = trips.load_id;


-- =========================================================
-- View: vw_load_trip
-- Purpose:
--   Combines load and route information for logistics analysis.
--
-- Description:
--   - Displays shipment details alongside origin and
--     destination locations
--   - Includes standard route distance for comparison
--
-- Use Cases:
--   Route planning analysis, shipment tracking reports,
--   logistics optimization
-- =========================================================
CREATE OR REPLACE VIEW `vw_load_trip` AS
	SELECT
		loads.load_date AS `date`,
		loads.load_type AS `type`,
		loads.weight_lbs AS `weight(lbs)`,
		loads.pieces AS `pieces`,
		routes.origin_state AS `origin_state`,
		routes.origin_city AS `origin_city`,
		routes.destination_state AS `destination_state`,
		routes.destination_city AS `destination_city`,
		routes.typical_distance_miles AS `distance(mi)`

		FROM loads
		LEFT JOIN routes ON routes.route_id = loads.route_id;


-- ============================================================
-- SECTION 2: PERFORMANCE INDEXES
-- ============================================================

-- Customers: support filtering and lookup by name and type
CREATE INDEX `customer_name_INDEX` ON customers(customer_name);
CREATE INDEX `customer_type_INDEX` ON customers(customer_type);

-- Drivers: support name-based searches and full-name lookups
CREATE INDEX `driver_first_name_INDEX` ON drivers(first_name);
CREATE INDEX `driver_last_name_INDEX` ON drivers(last_name);
CREATE INDEX `driver_name_INDEX` ON drivers(first_name, last_name);

-- Facilities: support filtering by name and type
CREATE INDEX `facility_name_INDEX` ON facilities(facility_name);
CREATE INDEX `facility_type_INDEX` ON facilities(facility_type);

-- Trailers: support unit number and type-based lookups
CREATE INDEX `trailer_number_INDEX` ON trailers(trailer_number);
CREATE INDEX `trailer_type_INDEX` ON trailers(trailer_type);

-- Trucks: support unit number, make, and tank capacity queries
CREATE INDEX `truck_unit_number_INDEX` ON trucks(unit_number);
CREATE INDEX `truck_make_INDEX` ON trucks(make);
CREATE INDEX `tank_capacity_gallons_INDEX` ON trucks(tank_capacity_gallons);
