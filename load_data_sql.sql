-- ============================================================
-- FILE: 04_load_data.sql
-- PURPOSE:
--   Loads all source CSV datasets into the logistics schema
--   using MySQL's LOAD DATA LOCAL INFILE statement.
--
-- DEPENDENCIES:
--   Must be executed after 02_schema.sql (tables must exist).
--   local_infile must be enabled (handled in 01_connect.sql).
--
-- IMPORTANT:
--   Update the file paths below to match the absolute path
--   of your local datasets directory before running this file.
--
-- TABLE LOAD ORDER (respects foreign key constraints):
--   1. customers         (no dependencies)
--   2. drivers           (no dependencies)
--   3. facilities        (no dependencies)
--   4. routes            (no dependencies)
--   5. loads             (depends on: customers, routes)
--   6. trailers          (no dependencies)
--   7. trucks            (no dependencies)
--   8. trips             (depends on: loads, drivers, trucks, trailers)
--   9. delivery_events   (depends on: loads, trips, facilities)
--  10. fuel_purchases    (depends on: trips, trucks, drivers)
--  11. safety_incidents  (depends on: trips, trucks, drivers)
--  12. maintenance_records (depends on: trucks)
-- ============================================================

USE `logistics`;


-- ------------------------------------------------------------
-- 1. customers
-- Records: varies | Dependencies: none
-- ------------------------------------------------------------
LOAD DATA LOCAL INFILE 'ABSOLUTE FILE PATH'
INTO TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '/n'
IGNORE 1 ROWS
(
	customer_id,
	customer_name,
	customer_type,
	credit_terms_days,
	primary_freight_type,
	account_status,
	contract_start_date,
	annual_revenue_potential
);


-- ------------------------------------------------------------
-- 2. drivers
-- Records: varies | Dependencies: none
-- ------------------------------------------------------------
LOAD DATA LOCAL INFILE 'ABSOLUTE FILE PATH'
INTO TABLE drivers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '/n'
IGNORE 1 ROWS
(
	driver_id,
	first_name,
	last_name,
	hire_date,
	termination_date,
	license_number,
	license_state,
	date_of_birth,
	home_terminal,
	employment_status,
	cdl_class,
	year_experience
);


-- ------------------------------------------------------------
-- 3. facilities
-- Records: varies | Dependencies: none
-- ------------------------------------------------------------
LOAD DATA LOCAL INFILE 'ABSOLUTE FILE PATH'
INTO TABLE facilities
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '/n'
IGNORE 1 ROWS;


-- ------------------------------------------------------------
-- 4. routes
-- Records: varies | Dependencies: none
-- ------------------------------------------------------------
LOAD DATA LOCAL INFILE 'ABSOLUTE FILE PATH'
INTO TABLE routes
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '/n'
IGNORE 1 ROWS;


-- ------------------------------------------------------------
-- 5. loads
-- Records: varies | Dependencies: customers, routes
-- ------------------------------------------------------------
LOAD DATA LOCAL INFILE 'ABSOLUTE FILE PATH'
INTO TABLE loads
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '/n'
IGNORE 1 ROWS;


-- ------------------------------------------------------------
-- 6. trailers
-- Records: varies | Dependencies: none
-- ------------------------------------------------------------
LOAD DATA LOCAL INFILE 'ABSOLUTE FILE PATH'
INTO TABLE trailers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '/n'
IGNORE 1 ROWS
(
	trailer_id,
	trailer_number,
	trailer_type,
	length_feet,
	model_year,
	vin,
	acquisition_date,
	status,
	current_location
);


-- ------------------------------------------------------------
-- 7. trucks
-- Records: varies | Dependencies: none
-- ------------------------------------------------------------
LOAD DATA LOCAL INFILE 'ABSOLUTE FILE PATH'
INTO TABLE trucks
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '/n'
IGNORE 1 ROWS
(
	truck_id,
	unit_number,
	make,
	model_year,
	vin,
	acquistion_date,
	acquistion_mileage,
	fuel_type,
	tank_capacity_gallons,
	status,
	home_terminal
);


-- ------------------------------------------------------------
-- 8. trips
-- Records: ~85,410 loaded | Skipped: ~4,952 (FK violations)
-- Dependencies: loads, drivers, trucks, trailers
-- ------------------------------------------------------------
LOAD DATA LOCAL INFILE 'ABSOLUTE FILE PATH'
INTO TABLE trips
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '/n'
IGNORE 1 ROWS
(
	trip_id,
	load_id,
	driver_id,
	truck_id,
	trailer_id,
	dispatch_date,
	actual_distance_miles,
	actual_duration_hours,
	fuel_gallons_used,
	average_mpg,
	idle_time_hours,
	trip_status
);


-- ------------------------------------------------------------
-- 9. delivery_events
-- Records: ~170,820 loaded | Skipped: ~9,904 (FK violations)
-- Dependencies: loads, trips, facilities
-- ------------------------------------------------------------
LOAD DATA LOCAL INFILE 'ABSOLUTE FILE PATH'
INTO TABLE delivery_events
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '/n'
IGNORE 1 ROWS
(
	event_id,
	load_id,
	trip_id,
	event_type,
	facility_id,
	scheduled_datetime,
	actual_datetime,
	detention_minutes,
	on_time_flag,
	location_city,
	location_state
);


-- ------------------------------------------------------------
-- 10. fuel_purchases
-- Records: ~196,442 loaded | Skipped: ~11,391 (FK violations)
-- Dependencies: trips, trucks, drivers
-- ------------------------------------------------------------
LOAD DATA LOCAL INFILE 'ABSOLUTE FILE PATH'
INTO TABLE fuel_purchases
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '/n'
IGNORE 1 ROWS
(
	fuel_purchase_id,
	trip_id,
	truck_id,
	driver_id,
	purchase_date,
	location_city,
	location_state,
	gallons,
	price_per_gallon,
	total_cost,
	fuel_card_number
);


-- ------------------------------------------------------------
-- 11. safety_incidents
-- Records: ~170 loaded | Skipped: ~5 (FK violations)
-- Dependencies: trips, trucks, drivers
-- ------------------------------------------------------------
LOAD DATA LOCAL INFILE 'ABSOLUTE FILE PATH'
INTO TABLE safety_incidents
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '/n'
IGNORE 1 ROWS
(
	incident_id,
	trip_id,
	truck_id,
	driver_id,
	incident_date,
	incident_type,
	location_city,
	location_state,
	at_fault_flag,
	injury_flag,
	vehicle_damage_cost,
	cargo_damage_cost,
	claim_amount,
	preventable_flag,
	description
);


-- ------------------------------------------------------------
-- 12. maintenance_records
-- Records: ~2,920 loaded | Skipped: 0
-- Dependencies: trucks
-- ------------------------------------------------------------
LOAD DATA LOCAL INFILE 'ABSOLUTE FILE PATH'
INTO TABLE `maintenance_records`
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '/n'
IGNORE 1 ROWS
(
	maintenance_id,
	truck_id,
	maintenance_date,
	maintenance_type,
	odometer_reading,
	labor_hours,
	labor_cost,
	parts_cost,
	total_cost,
	facility_location,
	downtime_hours,
	service_description
);

