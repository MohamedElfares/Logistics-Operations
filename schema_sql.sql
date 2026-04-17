-- ============================================================
-- FILE: 02_schema.sql
-- PURPOSE:
--   Defines all tables, relationships, constraints, and
--   business logic triggers for the logistics database.
--
-- DEPENDENCIES:
--   Must be executed after 01_connect.sql
--
-- SECTIONS:
--   1. Table Definitions
--   2. Stored Procedures
--   3. Utility Function
--   4. Triggers (Data Formatting & Business Rules)
-- ============================================================

USE `logistics`;


-- ============================================================
-- SECTION 1: TABLE DEFINITIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS `customers` (
	`customer_id`				VARCHAR(16),
	`customer_name`				VARCHAR(32) NOT NULL,
	`customer_type`				ENUM('Dedicated', 'Contract', 'Spot') NOT NULL,
	`credit_terms_days`			SMALLINT,
	`primary_freight_type`		ENUM('General', 'Retail', 'Consumer Goods', 'Food/Beverage', 'Automotive', 'Electronics') NOT NULL,
	`account_status`			ENUM('Active', 'Inactive') DEFAULT 'Active',
	`contract_start_date`		DATE,
	`annual_revenue_potential`	INT,

	CONSTRAINT customers_id_PK PRIMARY KEY(`customer_id`)
);

CREATE TABLE IF NOT EXISTS `drivers` (
	`driver_id`			VARCHAR(16),
	`first_name`		VARCHAR(32) NOT NULL,
	`last_name`			VARCHAR(32) NOT NULL,
	`hire_date`			DATE NOT NULL,
	`termination_date`	DATE,
	`license_number`	VARCHAR(16) UNIQUE NOT NULL,
	`license_state`		CHAR(2) NOT NULL,
	`date_of_birth`		DATE,
	`home_terminal`		VARCHAR(32),
	`employment_status`	ENUM('Active', 'Terminated') DEFAULT 'Active',
	`cdl_class`			ENUM('A', 'B', 'C') DEFAULT 'A',
	`year_experience`	SMALLINT,

	CONSTRAINT drivers_id_PK PRIMARY KEY(`driver_id`)
);

CREATE TABLE IF NOT EXISTS `facilities` (
	`facility_id`		VARCHAR(16),
	`facility_name`		VARCHAR(64)	NOT NULL,
	`facility_type`		ENUM('Cross-Dock', 'Distribution Center', 'Terminal', 'Warehouse') NOT NULL,
	`city`				VARCHAR(32) NOT NULL,
	`state`				CHAR(2) NOT NULL,
	`latitude`			FLOAT,
	`longitude`			FLOAT,
	`dock_doors`		SMALLINT,
	`operating_hours`	VARCHAR(32),

	CONSTRAINT facilities_id_PK PRIMARY KEY(`facility_id`)
);

CREATE TABLE IF NOT EXISTS `routes` (
	`route_id`					VARCHAR(16),
	`origin_city`				VARCHAR(32) NOT NULL,
	`origin_state`				CHAR(2) NOT NULL,
	`destination_city`			VARCHAR(32) NOT NULL,
	`destination_state`			CHAR(2) NOT NULL,
	`typical_distance_miles`	SMALLINT,
	`base_rate_per_mile`		FLOAT,
	`fuel_surcharge_rate`		FLOAT,
	`typical_transit_days`		TINYINT,

	CONSTRAINT routes_id_PK PRIMARY KEY(`route_id`)
);

CREATE TABLE IF NOT EXISTS `loads` (
	`load_id`				VARCHAR(16),
	`customer_id`			VARCHAR(16),
	`route_id`				VARCHAR(16),
	`load_date`				DATE NOT NULL,
	`load_type`				ENUM('Dry Van', 'Refrigerated') NOT NULL,
	`weight_lbs`			SMALLINT NOT NULL,
	`pieces`				SMALLINT NOT NULL,
	`revenue`				FLOAT NOT NULL,
	`fuel_surcharge`		FLOAT NOT NULL,
	`accessorial_charges`	SMALLINT,
	`load_status`			VARCHAR(24) DEFAULT 'Completed',
	`booking_type`			ENUM('Spot', 'Dedicated', 'Contract') NOT NULL,

	CONSTRAINT loads_id_PK PRIMARY KEY(`load_id`),
	CONSTRAINT loads_customers_id_FK FOREIGN KEY(`customer_id`) REFERENCES `customers`(`customer_id`),
	CONSTRAINT loads_routes_id_FK FOREIGN KEY(`route_id`) REFERENCES `routes`(`route_id`)
);

CREATE TABLE IF NOT EXISTS `trailers` (
	`trailer_id`		VARCHAR(16),
	`trailer_number`	SMALLINT NOT NULL,
	`trailer_type`		ENUM('Dry Van', 'Refrigerated') NOT NULL,
	`length_feet`		TINYINT DEFAULT 53,
	`model_year`		YEAR,
	`vin`				VARCHAR(24) UNIQUE NOT NULL,
	`acquisition_date`	DATE,
	`status`			VARCHAR(24) DEFAULT 'Active',
	`current_location`	VARCHAR(32),

	CONSTRAINT trailers_id_PK PRIMARY KEY(`trailer_id`)
);

CREATE TABLE IF NOT EXISTS `trucks` (
	`truck_id`				VARCHAR(16),
	`unit_number`			SMALLINT UNIQUE NOT NULL,
	`make`					VARCHAR(32) NOT NULL,
	`model_year`			YEAR,
	`vin`					VARCHAR(24) UNIQUE NOT NULL,
	`acquistion_date`		DATE,
	`acquistion_mileage`	SMALLINT,
	`fuel_type`				VARCHAR(16) DEFAULT 'Diesel',
	`tank_capacity_gallons`	SMALLINT,
	`status`				ENUM('Active', 'Maintenance', 'Inactive') NOT NULL,
	`home_terminal`			VARCHAR(32),

	CONSTRAINT trucks_id_PK PRIMARY KEY(`truck_id`)
);

CREATE TABLE IF NOT EXISTS `trips` (
	`load_id`				VARCHAR(16),
	`driver_id`				VARCHAR(16),
	`trip_id`				VARCHAR(16),
	`truck_id`				VARCHAR(16),
	`trailer_id`			VARCHAR(16),
	`dispatch_date`			DATE,
	`actual_distance_miles` SMALLINT,
	`actual_duration_hours` FLOAT,
	`fuel_gallons_used`		FLOAT,
	`average_mpg`			FLOAT,
	`idle_time_hours`		FLOAT,
	`trip_status`			VARCHAR(24) DEFAULT 'Completed',

	CONSTRAINT trips_id_PK PRIMARY KEY(`trip_id`),
	CONSTRAINT trips_loads_id FOREIGN KEY(`load_id`) REFERENCES `loads`(`load_id`),
	CONSTRAINT trips_drivers_id FOREIGN KEY(`driver_id`) REFERENCES `drivers`(`driver_id`),
	CONSTRAINT trips_trucks_id FOREIGN KEY(`truck_id`) REFERENCES `trucks`(`truck_id`),
	CONSTRAINT trips_trailers_id FOREIGN KEY(`trailer_id`) REFERENCES `trailers`(`trailer_id`)
);

CREATE TABLE IF NOT EXISTS `delivery_events` (
	`event_id`				VARCHAR(16),
	`load_id`				VARCHAR(16),
	`trip_id`				VARCHAR(16),
	`event_type`			ENUM('Delivery', 'Pickup') NOT NULL,
	`facility_id`			VARCHAR(16),
	`scheduled_datetime`	DATETIME(6),
	`actual_datetime`		DATETIME(6),
	`detention_minutes`		SMALLINT,
	`on_time_flag`			VARCHAR(5),
	`location_city`			VARCHAR(32),
	`location_state`		CHAR(2),

	CONSTRAINT delivery_events_id_PK PRIMARY KEY(`event_id`),
	CONSTRAINT delivery_events_loads_id FOREIGN KEY(`load_id`) REFERENCES `loads`(`load_id`),
	CONSTRAINT delivery_events_trips_id FOREIGN KEY(`trip_id`) REFERENCES `trips`(`trip_id`),
	CONSTRAINT delivery_events_facility_id FOREIGN KEY(`facility_id`) REFERENCES `facilities`(`facility_id`)
);

CREATE TABLE IF NOT EXISTS `fuel_purchases` (
	`fuel_purchase_id`		VARCHAR(16),
	`trip_id`				VARCHAR(16),
	`truck_id`				VARCHAR(16),
	`driver_id`				VARCHAR(16),
	`purchase_date`			DATETIME DEFAULT NOW(),
	`location_city`			VARCHAR(32) NOT NULL,
	`location_state`		CHAR(2) NOT NULL,
	`gallons`				FLOAT NOT NULL,
	`price_per_gallon`		FLOAT NOT NULL,
	`total_cost`			FLOAT NOT NULL,
	`fuel_card_number`		VARCHAR(16) NOT NULL,

	CONSTRAINT fuel_purcheses_id_PK PRIMARY KEY(`fuel_purchase_id`),
	CONSTRAINT fuel_purcheses_trips_id FOREIGN KEY(`trip_id`) REFERENCES `trips`(`trip_id`),
	CONSTRAINT fuel_purcheses_trucks_id FOREIGN KEY(`truck_id`) REFERENCES `trucks`(`truck_id`),
	CONSTRAINT fuel_purcheses_drivers_id FOREIGN KEY(`driver_id`) REFERENCES `drivers`(`driver_id`)
);

CREATE TABLE IF NOT EXISTS `safety_incidents` (
	`incident_id`			VARCHAR(16),
	`trip_id`				VARCHAR(16),
	`truck_id`				VARCHAR(16),
	`driver_id`				VARCHAR(16),
	`incident_date`			DATETIME,
	`incident_type`			VARCHAR(64),
	`location_city`			VARCHAR(32),
	`location_state`		CHAR(2),
	`at_fault_flag`			VARCHAR(5),
	`injury_flag`			VARCHAR(5),
	`vehicle_damage_cost`	FLOAT,
	`cargo_damage_cost`		FLOAT,
	`claim_amount`			FLOAT,
	`preventable_flag`		VARCHAR(5),
	`description`			TEXT,

	CONSTRAINT safety_incidents_id_PK PRIMARY KEY(`incident_id`),
	CONSTRAINT safety_incidents_trips_id FOREIGN KEY(`trip_id`) REFERENCES `trips`(`trip_id`),
	CONSTRAINT safety_incidents_trucks_id FOREIGN KEY(`truck_id`) REFERENCES `trucks`(`truck_id`),
	CONSTRAINT safety_incidents_drivers_id FOREIGN KEY(`driver_id`) REFERENCES `drivers`(`driver_id`)
);

CREATE TABLE IF NOT EXISTS `maintenance_records` (
	`maintenance_id`		VARCHAR(16),
	`truck_id`				VARCHAR(16),
	`maintenance_date`		DATE,
	`maintenance_type`		ENUM('Inspection', 'Tire', 'Preventive', 'Repair', 'Transmission', 'Brake', 'Engine'),
	`odometer_reading`		INT,
	`labor_hours`			FLOAT,
	`labor_cost`			FLOAT,
	`parts_cost`			FLOAT,
	`total_cost`			FLOAT,
	`facility_location`		VARCHAR(32),
	`downtime_hours`		FLOAT,
	`service_description`	TEXT,

	CONSTRAINT maintenance_id_PK PRIMARY KEY(`maintenance_id`),
	CONSTRAINT maintenance_truck_id FOREIGN KEY(`truck_id`) REFERENCES `trucks`(`truck_id`)
);


-- ============================================================
-- SECTION 2: STORED PROCEDURES
-- ============================================================

DELIMITER //

-- =========================================================
-- Procedure: sp_customer_revenue
-- Purpose:
--   Calculates total revenue generated by a specific customer.
--   Returns aggregated revenue from the loads table.
--
-- Parameter:
--   cust_id → Customer ID to filter revenue records
-- =========================================================
CREATE PROCEDURE sp_customer_revenue(IN cust_id VARCHAR(16))
BEGIN
	SELECT
		customer_id,
		SUM(revenue) AS total_revenue
	FROM loads
	WHERE customer_id = cust_id
	GROUP BY customer_id;
END //

-- =========================================================
-- Procedure: sp_update_trip_mpg
-- Purpose:
--   Recalculates and updates the average MPG for a specific trip.
--   Uses actual distance and fuel consumption values.
--
-- Parameter:
--   trip → Trip ID whose MPG needs recalculation
--
-- Note:
--   Assumes fuel_gallons_used is NOT zero (no safety check)
-- =========================================================
CREATE PROCEDURE sp_update_trip_mpg(IN trip VARCHAR(16))
BEGIN
	UPDATE trips
	SET average_mpg = actual_distance_miles / fuel_gallons_used
	WHERE trip_id = trip;
END //

-- =========================================================
-- Procedure: sp_truck_maintenance
-- Purpose:
--   Provides a maintenance summary for a specific truck,
--   including total service count and cumulative cost.
--
-- Parameter:
--   truck → Truck ID for maintenance aggregation
-- =========================================================
CREATE PROCEDURE sp_truck_maintenance(IN truck VARCHAR(16))
BEGIN
	SELECT
		COUNT(*) AS total_services,
		SUM(total_cost) AS total_cost
	FROM maintenance_records
	WHERE truck_id = truck;
END //


-- ============================================================
-- SECTION 3: UTILITY FUNCTION
-- ============================================================

-- =========================================================
-- Function: Capitalize
-- Purpose:
--   Standardizes text formatting by:
--     - Removing leading and trailing spaces
--     - Collapsing multiple internal spaces into one
--     - Capitalizing the first letter of each word
--     - Converting all remaining letters to lowercase
--
-- Example:
--   '   jOhN    DOE  '  →  'John Doe'
--
-- Notes:
--   Deterministic: identical input always produces identical output.
--   Used internally by all INSERT and UPDATE triggers.
-- =========================================================
CREATE FUNCTION Capitalize(input VARCHAR(255)) 
RETURNS VARCHAR(255) 
DETERMINISTIC
BEGIN
    DECLARE word_count SMALLINT;
    DECLARE i SMALLINT DEFAULT 1;
    DECLARE current_word TINYTEXT;
    DECLARE capitalized VARCHAR(255);
    DECLARE in_string VARCHAR(255);

    IF input IS NULL THEN
        RETURN NULL;
    END IF;

    SET in_string = TRIM(input);

    IF in_string = '' THEN
        RETURN '';
    END IF;

    -- Normalize internal spacing
    WHILE in_string LIKE '%  %' DO
        SET in_string = REPLACE(in_string, '  ', ' ');
    END WHILE;

    -- Count words
    SET word_count = LENGTH(in_string) - LENGTH(REPLACE(in_string, ' ', '')) + 1;

    SET capitalized = '';

    WHILE i <= word_count DO
        SET current_word = SUBSTRING_INDEX(SUBSTRING_INDEX(in_string, ' ', i), ' ', -1);

        SET capitalized = CONCAT(
            capitalized,
            IF(i = 1, '', ' '),
            UPPER(LEFT(current_word, 1)),
            LOWER(SUBSTRING(current_word, 2))
        );

        SET i = i + 1;
    END WHILE;

    RETURN capitalized;
END //


-- ============================================================
-- SECTION 4: TRIGGERS
-- ============================================================

-- =========================================================
-- Trigger: new_customer
-- Purpose:
--   Automatically formats customer_name before insertion
--   to ensure consistent capitalization across all records.
-- =========================================================
CREATE TRIGGER `new_customer`
BEFORE INSERT ON customers
FOR EACH ROW
BEGIN
	SET
		NEW.customer_name = Capitalize(NEW.customer_name);
END //

-- =========================================================
-- Trigger: hire_driver
-- Purpose:
--   Standardizes driver information before insertion by:
--     - Capitalizing names and free-text fields
--     - Converting license and state codes to uppercase
--     - Trimming leading and trailing whitespace
-- =========================================================
CREATE TRIGGER `hire_driver`
BEFORE INSERT ON drivers
FOR EACH ROW
BEGIN
    SET
		NEW.first_name       	= Capitalize(NEW.first_name),
		NEW.last_name         	= Capitalize(NEW.last_name),
		NEW.employment_status	= Capitalize(NEW.employment_status),
		NEW.home_terminal 		= Capitalize(NEW.home_terminal),
		NEW.license_state 		= UPPER(TRIM(NEW.license_state)),
		NEW.cdl_class     		= UPPER(TRIM(NEW.cdl_class));
END //

-- =========================================================
-- Trigger: driver_termination
-- Purpose:
--   Standardizes driver data before updates and automatically
--   sets employment_status to 'Terminated' when a
--   termination_date is newly provided.
-- =========================================================
CREATE TRIGGER `driver_termination`
BEFORE UPDATE ON drivers
FOR EACH ROW
BEGIN
	SET
		NEW.first_name       	= Capitalize(NEW.first_name),
		NEW.last_name         	= Capitalize(NEW.last_name),
		NEW.employment_status	= Capitalize(NEW.employment_status),
		NEW.home_terminal 		= Capitalize(NEW.home_terminal),
		NEW.license_state 		= UPPER(TRIM(NEW.license_state)),
		NEW.cdl_class     		= UPPER(TRIM(NEW.cdl_class));

	IF NEW.termination_date IS NOT NULL AND OLD.termination_date IS NULL THEN
		SET NEW.employment_status = 'Terminated';
	END IF;
END //

-- =========================================================
-- Trigger: add_facility
-- Purpose:
--   Standardizes facility location data before insertion
--   by capitalizing the facility name and city, and
--   converting the state code to uppercase.
-- =========================================================
CREATE TRIGGER `add_facility`
BEFORE INSERT ON facilities
FOR EACH ROW
BEGIN
	SET
		NEW.facility_name = Capitalize(NEW.facility_name),
		NEW.city = Capitalize(NEW.city),
		NEW.state = UPPER(NEW.state);
END //

-- =========================================================
-- Trigger: add_route
-- Purpose:
--   Ensures consistent formatting of route location fields
--   by capitalizing city and state values before insertion.
-- =========================================================
CREATE TRIGGER `add_route`
BEFORE INSERT ON routes
FOR EACH ROW
BEGIN
	SET
		NEW.origin_city = Capitalize(NEW.origin_city),
		NEW.origin_state = Capitalize(NEW.origin_state),
		NEW.destination_city = Capitalize(NEW.destination_city),
		NEW.destination_state = Capitalize(NEW.destination_state);
END //

-- =========================================================
-- Trigger: new_trailer
-- Purpose:
--   Ensures consistent formatting of trailer fields by
--   capitalizing type, status, and current_location
--   before insertion.
-- =========================================================
CREATE TRIGGER `new_trailer`
BEFORE INSERT ON trailers
FOR EACH ROW
BEGIN
	SET
		NEW.trailer_type = Capitalize(NEW.trailer_type),
		NEW.status = Capitalize(NEW.status),
		NEW.current_location = Capitalize(NEW.current_location);
END //

-- =========================================================
-- Trigger: new_truck
-- Purpose:
--   Standardizes truck details before insertion by
--   capitalizing the make and home_terminal fields.
-- =========================================================
CREATE TRIGGER `new_truck`
BEFORE INSERT ON trucks
FOR EACH ROW
BEGIN
	SET
		NEW.make = Capitalize(NEW.make),
		NEW.home_terminal = Capitalize(NEW.home_terminal);
END //

-- =========================================================
-- Trigger: new_trip
-- Purpose:
--   Standardizes trip status formatting and automatically
--   calculates average MPG from distance and fuel used.
--   Guards against division by zero.
-- =========================================================
CREATE TRIGGER `new_trip`
BEFORE INSERT ON trips
FOR EACH ROW
BEGIN
	SET NEW.trip_status = Capitalize(NEW.trip_status);

	IF NEW.fuel_gallons_used > 0 THEN
        SET NEW.average_mpg = NEW.actual_distance_miles / NEW.fuel_gallons_used;
    ELSE
        SET NEW.average_mpg = 0;
    END IF;
END //

-- =========================================================
-- Trigger: new_event
-- Purpose:
--   Standardizes event location formatting and automatically
--   computes on_time_flag by comparing actual vs. scheduled
--   datetime values.
-- =========================================================
CREATE TRIGGER `new_event`
BEFORE INSERT ON delivery_events
FOR EACH ROW
BEGIN
	SET
		NEW.location_city = Capitalize(NEW.location_city),
		NEW.location_state = UPPER(NEW.location_state),
		NEW.on_time_flag = (NEW.actual_datetime <= NEW.scheduled_datetime);
END //

-- =========================================================
-- Trigger: new_fuel_purchases
-- Purpose:
--   Standardizes fuel purchase location formatting and
--   automatically calculates total_cost from gallons and
--   price_per_gallon. Handles NULL values safely via COALESCE.
-- =========================================================
CREATE TRIGGER `new_fuel_purchases`
BEFORE INSERT ON fuel_purchases
FOR EACH ROW
BEGIN
	SET
		NEW.location_city = Capitalize(NEW.location_city),
        NEW.location_state = UPPER(TRIM(NEW.location_state)),
        NEW.total_cost = COALESCE(NEW.gallons, 0) * COALESCE(NEW.price_per_gallon, 0);
END //

-- =========================================================
-- Trigger: new_incident
-- Purpose:
--   Standardizes incident location and type formatting and
--   converts boolean-like text values ('TRUE', '1') into
--   proper numeric boolean flags (0 or 1) for at_fault_flag,
--   injury_flag, and preventable_flag.
-- =========================================================
CREATE TRIGGER `new_incident`
BEFORE INSERT ON safety_incidents
FOR EACH ROW
BEGIN
	SET
		NEW.incident_type = Capitalize(NEW.incident_type),
		NEW.location_city = Capitalize(NEW.location_city),
		NEW.location_state = UPPER(NEW.location_state);

	IF NEW.at_fault_flag LIKE 'TRUE' OR NEW.at_fault_flag = '1' THEN
		SET NEW.at_fault_flag = 1;
	ELSE
		SET NEW.at_fault_flag = 0;
	END IF;

	IF NEW.injury_flag LIKE 'TRUE' OR NEW.injury_flag = '1' THEN
		SET NEW.injury_flag = 1;
	ELSE
		SET NEW.injury_flag = 0;
	END IF;

	IF NEW.preventable_flag LIKE 'TRUE' OR NEW.preventable_flag = '1' THEN
		SET NEW.preventable_flag = 1;
	ELSE
		SET NEW.preventable_flag = 0;
	END IF;
END //

DELIMITER ;
