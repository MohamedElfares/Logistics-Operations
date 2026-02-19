-- Drop the schema for test porpeses.
DROP SCHEMA IF EXISTS `logistics`;

-- Create new schema calle	d logistics.
CREATE SCHEMA IF NOT EXISTS `logistics`;
USE `logistics`;

CREATE TABLE IF NOT EXISTS `customers` (
	`customer_id`				VARCHAR(16),            -- Unique identifier for each customer
	`customer_name`				VARCHAR(32) NOT NULL,   -- Customer display name (free text)
	`customer_type`				ENUM('Dedicated', 'Contract', 'Spot') NOT NULL, -- Controlled customer classification
	`credit_terms_days`			SMALLINT,               -- Credit terms in days
	`primary_freight_type`		ENUM('General', 'Retail', 'Consumer Goods', 'Food/Beverage', 'Automotive', 'Electronics') NOT NULL,  -- Primary freight category (controlled vocabulary)
	`account_status`			ENUM('Active', 'Inactive') DEFAULT 'Active',    -- Account activity status
	`contract_start_date`		DATE,	                -- Contract start date (if applicable)
	`annual_revenue_potential`	INT,                    -- Estimated annual revenue
	
	-- Primary key constraint
	CONSTRAINT customers_id_PK PRIMARY KEY(`customer_id`)
);

CREATE TABLE IF NOT EXISTS `drivers` (
	`driver_id`			VARCHAR(16),                    -- Unique identifier for each driver
	`first_name`		VARCHAR(32) NOT NULL,	        -- Driver's legal first name
	`last_name`			VARCHAR(32) NOT NULL,	        -- Driver's legal last name
	`hire_date`			DATE NOT NULL,	                -- Date the driver was hired
	`termination_date`	DATE,	                        -- Date the driver was terminated (NULL if still employed)
	`license_number`	VARCHAR(16) UNIQUE NOT NULL,    -- Commercial driver's license number
	`license_state`		CHAR(2) NOT NULL,	            -- Two-letter US state code issuing the license (e.g., CA, TX)
	`date_of_birth`		DATE,	                        -- Driver's date of birth
	`home_terminal`		VARCHAR(32),	                -- Home terminal or base location
	`employment_status`	ENUM('Active', 'Terminated') DEFAULT 'Active',  -- Current employment status
	`cdl_class`			ENUM('A', 'B', 'C') DEFAULT 'A',	            -- CDL classification
	`year_experience`	SMALLINT,	                    -- Total years of driving experience
	
	-- Primary key constraint
	CONSTRAINT drivers_id_PK PRIMARY KEY(`driver_id`)
);

CREATE TABLE IF NOT EXISTS `facilities` (
	`facility_id`		VARCHAR(16),	        -- Unique identifier for each facility
	`facility_name`		VARCHAR(64)	NOT NULL,	-- Facility name (e.g., "Chicago DC 01")
	`facility_type`		ENUM('Cross-Dock', 'Distribution Center', 'Terminal', 'Warehouse') NOT NULL,	-- Type of facility (controlled vocabulary)
	`city`				VARCHAR(32) NOT NULL,	-- City where the facility is located
	`state`				CHAR(2) NOT NULL,	    -- State code (2-letter US state)
	`latitude`			FLOAT,	                -- Geographic coordinates (latitude) (optional)
	`longitude`			FLOAT,	                -- Geographic coordinates (longitude) (optional)
	`dock_doors`		SMALLINT,	            -- Number of dock doors
	`operating_hours`	VARCHAR(32),	        -- Operating hours
	
	-- Primary key constraint
	CONSTRAINT facilities_id_PK PRIMARY KEY(`facility_id`)
);

CREATE TABLE IF NOT EXISTS `routes` (
	`route_id`					VARCHAR(16),            -- Unique identifier for each transportation route
	`origin_city`				VARCHAR(32) NOT NULL,   -- Origin city where the route begins
	`origin_state`				CHAR(2) NOT NULL,       -- Two-letter state code of the origin location
	`destination_city`			VARCHAR(32) NOT NULL,   -- Destination city where the route ends
	`destination_state`			CHAR(2) NOT NULL,       -- Two-letter state code of the destination location
	`typical_distance_miles`	SMALLINT,               -- Standard estimated distance of the route in miles
	`base_rate_per_mile`		FLOAT,                  -- Base transportation charge per mile for the route
	`fuel_surcharge_rate`		FLOAT,                  -- Standard fuel surcharge rate applied to the route
	`typical_transit_days`		TINYINT,                -- Estimated number of days required for delivery
	
	-- Primary key constraint
	CONSTRAINT routes_id_PK PRIMARY KEY(`route_id`)
);

CREATE TABLE IF NOT EXISTS `loads` (
	`load_id`				VARCHAR(16),        -- Unique identifier for each shipment load
	`customer_id`			VARCHAR(16),        -- Reference to the customer who booked the load
	`route_id`				VARCHAR(16),        -- Reference to the route assigned to the load
	`load_date`				DATE NOT NULL,      -- Date when the load was scheduled or dispatched
	`load_type`				ENUM('Dry Van', 'Refrigerated') NOT NULL,   -- Type of trailer required for the shipment
	`weight_lbs`			SMALLINT NOT NULL,  -- Total shipment weight in pounds
	`pieces`				SMALLINT NOT NULL,  -- Number of handling units or packages in the shipment
	`revenue`				FLOAT NOT NULL,     -- Total revenue generated from the load
	`fuel_surcharge`		FLOAT NOT NULL,     -- Fuel surcharge amount applied to the load
	`accessorial_charges`	SMALLINT,           -- Additional service fees (e.g., detention, liftgate)
	`load_status`			VARCHAR(24) DEFAULT 'Completed',                -- Current operational status of the load
	`booking_type`			ENUM('Spot', 'Dedicated', 'Contract') NOT NULL, -- Contract type under which the load was booked
	
	-- Primary key constraint
	CONSTRAINT loads_id_PK PRIMARY KEY(`load_id`),
	
	-- Foreign key constraints
	CONSTRAINT loads_customers_id_FK FOREIGN KEY(`customer_id`) REFERENCES `customers`(`customer_id`),
	CONSTRAINT loads_routes_id_FK FOREIGN KEY(`route_id`) REFERENCES `routes`(`route_id`)
);

CREATE TABLE IF NOT EXISTS `trailers` (
	`trailer_id`		VARCHAR(16),                    -- Unique identifier for each trailer
	`trailer_number`	SMALLINT NOT NULL,
	`trailer_type`		ENUM('Dry Van', 'Refrigerated') NOT NULL,   -- Internal fleet unit number assigned to the trailer
	`length_feet`		TINYINT DEFAULT 53,             -- Trailer configuration type
	`model_year`		YEAR,                           -- Manufacturing year of the trailer
	`vin`				VARCHAR(24) UNIQUE NOT NULL,    -- Vehicle Identification Number (VIN)
	`acquisition_date`	DATE,                           -- Date when the trailer was acquired by the company
	`status`			VARCHAR(24) DEFAULT 'Active',   -- Operational status of the trailer
	`current_location`	VARCHAR(32),                    -- Current city or terminal where the trailer is located

	-- Primary key constraint
	CONSTRAINT trailers_id_PK PRIMARY KEY(`trailer_id`)
);

CREATE TABLE IF NOT EXISTS `trucks` (
	`truck_id`				VARCHAR(16),                    -- Unique identifier for each truck unit
	`unit_number`			SMALLINT UNIQUE NOT NULL,       -- Internal fleet unit number assigned to the truck
	`make`					VARCHAR(32) NOT NULL,           -- Manufacturer brand of the truck
	`model_year`			YEAR,                           -- Manufacturing year of the truck
	`vin`					VARCHAR(24) UNIQUE NOT NULL,    -- Vehicle Identification Number (VIN)
	`acquistion_date`		DATE,							-- Date when the truck was purchased or added to the fleet
	`acquistion_mileage`	SMALLINT,						-- Odometer reading at the time of acquisition
	`fuel_type`				VARCHAR(16) DEFAULT 'Diesel',	-- Type of fuel used by the truck
	`tank_capacity_gallons`	SMALLINT,						-- Maximum fuel tank capacity in gallons
	`status`				ENUM('Active', 'Maintenance', 'Inactive') NOT NULL,	-- Current operational status
	`home_terminal`			VARCHAR(32),					-- Primary operating terminal assigned to the truck
	
	-- Primary key constraint
	CONSTRAINT trucks_id_PK PRIMARY KEY(`truck_id`)
);

CREATE TABLE IF NOT EXISTS `trips` (
	`load_id`				VARCHAR(16),	-- Unique identifier for each trip record
	`driver_id`				VARCHAR(16),	-- Reference to the associated shipment load
	`trip_id`				VARCHAR(16),	-- Reference to the driver assigned to the trip
	`truck_id`				VARCHAR(16),	-- Reference to the truck used for the trip
	`trailer_id`			VARCHAR(16),	-- Reference to the trailer used for the trip
	`dispatch_date`			DATE,			-- Date when the trip was dispatched
	`actual_distance_miles` SMALLINT,		-- Actual distance traveled during the trip
	`actual_duration_hours` FLOAT,			-- Total driving duration in hours
	`fuel_gallons_used`		FLOAT,			-- Total fuel consumed during the trip
	`average_mpg`			FLOAT,			-- Calculated fuel efficiency in miles per gallon
	`idle_time_hours`		FLOAT,			-- Total engine idle time during the trip
	`trip_status`			VARCHAR(24) DEFAULT 'Completed',	-- Current execution status of the trip
	
	-- Primary key constraint
	CONSTRAINT trips_id_PK PRIMARY KEY(`trip_id`),

	-- Foreign key constraints
	CONSTRAINT trips_loads_id FOREIGN KEY(`load_id`) REFERENCES `loads`(`load_id`),
	CONSTRAINT trips_drivers_id FOREIGN KEY(`driver_id`) REFERENCES `drivers`(`driver_id`),
	CONSTRAINT trips_trucks_id FOREIGN KEY(`truck_id`) REFERENCES `trucks`(`truck_id`),
	CONSTRAINT trips_trailers_id FOREIGN KEY(`trailer_id`) REFERENCES `trailers`(`trailer_id`)
);


CREATE TABLE IF NOT EXISTS `delivery_events` (
	`event_id`				VARCHAR(16),	-- Unique identifier for each delivery event
	`load_id`				VARCHAR(16),	-- Reference to the associated shipment load
	`trip_id`				VARCHAR(16),	-- Reference to the trip during which the event occurred
	`event_type`			ENUM('Delivery', 'Pickup') NOT NULL,	-- Type of logistics event
	`facility_id`			VARCHAR(16),	-- Reference to the facility where the event occurred
	`scheduled_datetime`	DATETIME(6),	-- Planned date and time for the event
	`actual_datetime`		DATETIME(6),	-- Actual date and time when the event occurred
	`detention_minutes`		SMALLINT,		-- Total detention time recorded in minutes
	`on_time_flag`			TINYINT(1),   	-- Indicator showing whether the event occurred on time
	`location_city`			VARCHAR(32),	-- City where the event took place
	`location_state`		CHAR(2),		-- Two-letter state code of the event location
	
	-- Primary key constraint
	CONSTRAINT delivery_events_id_PK PRIMARY KEY(`event_id`),

	-- Foreign key constraints
	CONSTRAINT delivery_events_loads_id FOREIGN KEY(`load_id`) REFERENCES `loads`(`load_id`),
	CONSTRAINT delivery_events_trips_id FOREIGN KEY(`trip_id`) REFERENCES `trips`(`trip_id`),
	CONSTRAINT delivery_events_facility_id FOREIGN KEY(`facility_id`) REFERENCES `facilities`(`facility_id`)
);

CREATE TABLE IF NOT EXISTS `fuel_purchases` (
	`fuel_purchase_id`		VARCHAR(16),			-- Unique identifier for each fuel purchase transaction
	`trip_id`				VARCHAR(16),			-- Reference to the related trip
	`truck_id`				VARCHAR(16),			-- Reference to the truck where fuel was purchased
	`driver_id`				VARCHAR(16),			-- Reference to the driver who made the purchase
	`purchase_date`			DATETIME DEFAULT NOW(),	-- Date and time when the fuel was purchased
	`location_city`			VARCHAR(32) NOT NULL,	-- City where the fuel purchase occurred
	`location_state`		CHAR(2) NOT NULL,		-- Two-letter state code of the fuel purchase location
	`gallons`				FLOAT NOT NULL,			-- Quantity of fuel purchased in gallons
	`price_per_gallon`		FLOAT NOT NULL,			-- Unit price of fuel per gallon
	`total_cost`			FLOAT NOT NULL,			-- Total cost of the fuel purchase (auto-calculated)
	`fuel_card_number`		VARCHAR(16) NOT NULL,	-- Fleet fuel card used for the transaction

    -- Primary key constraint
	CONSTRAINT fuel_purcheses_id_PK PRIMARY KEY(`fuel_purchase_id`),

	-- Foreign key constraints
	CONSTRAINT fuel_purcheses_trips_id FOREIGN KEY(`trip_id`) REFERENCES `trips`(`trip_id`),
	CONSTRAINT fuel_purcheses_trucks_id FOREIGN KEY(`truck_id`) REFERENCES `trucks`(`truck_id`),
	CONSTRAINT fuel_purcheses_drivers_id FOREIGN KEY(`driver_id`) REFERENCES `drivers`(`driver_id`)
);

CREATE TABLE IF NOT EXISTS `safety_incidents` (
	`incident_id`			VARCHAR(16),		-- Unique identifier for each safety incident
	`trip_id`				VARCHAR(16),		-- Reference to the trip during which the incident occurred
	`truck_id`				VARCHAR(16),		-- Reference to the truck involved in the incident
	`driver_id`				VARCHAR(16),		-- Reference to the driver involved in the incident
	`incident_date`			DATETIME,			-- Date and time when the incident occurred
	`incident_type`			VARCHAR(64),		-- Classification of the incident (e.g., collision, violation)
	`location_city`			VARCHAR(32),		-- City where the incident occurred
	`location_state`		CHAR(2),			-- Two-letter state code of the incident location
	`at_fault_flag`			TINYINT(1),			-- Indicator showing whether the driver was at fault
	`injury_flag`			TINYINT(1),			-- Indicator showing whether injuries were reported
	`vehicle_damage_cost`	FLOAT,				-- Estimated cost of vehicle damage
	`cargo_damage_cost`		FLOAT,				-- Estimated cost of cargo damage
	`claim_amount`			FLOAT,				-- Insurance claim amount related to the incident
	`preventable_flag`		TINYINT(1),			-- Indicator showing whether the incident was preventable
	`description`			TEXT,				-- Detailed description of the incident
	
	-- Primary key constraint
	CONSTRAINT safety_incidents_id_PK PRIMARY KEY(`incident_id`),

	-- Foreign key constraints
	CONSTRAINT safety_incidents_trips_id FOREIGN KEY(`trip_id`) REFERENCES `trips`(`trip_id`),
	CONSTRAINT safety_incidents_trucks_id FOREIGN KEY(`truck_id`) REFERENCES `trucks`(`truck_id`),
	CONSTRAINT safety_incidents_drivers_id FOREIGN KEY(`driver_id`) REFERENCES `drivers`(`driver_id`)
);

CREATE TABLE IF NOT EXISTS `maintenance_records` (
	`maintenance_id`		VARCHAR(16),	-- Unique identifier for each maintenance record
	`truck_id`				VARCHAR(16),	-- Reference to the truck serviced
	`maintenance_date`		DATE,			-- Date when maintenance was performed
	`maintenance_type`		ENUM('Inspection', 'Tire', 'Preventive', 'Repair', 'Transmission', 'Brake', 'Engine'),	-- Type of maintenance service performed
	`odometer_reading`		INT,			-- Odometer reading at the time of service
	`labor_hours`			FLOAT,			-- Total labor hours spent on the maintenance task
	`labor_cost`			FLOAT,			-- Total labor cost for the service
	`parts_cost`			FLOAT,			-- Total cost of replacement parts used
	`total_cost`			FLOAT,			-- Total maintenance cost (labor + parts)
	`facility_location`		VARCHAR(32),	-- Service facility location where maintenance was performed
	`downtime_hours`		FLOAT,			-- Total operational downtime caused by the maintenance
	`service_description`	TEXT,			-- Detailed description of the maintenance work performed

	-- Primary key constraint
	CONSTRAINT maintenance_id_PK PRIMARY KEY(`maintenance_id`),

	-- Foreign key constraints
	CONSTRAINT maintenance_truck_id FOREIGN KEY(`truck_id`) REFERENCES `trucks`(`truck_id`)
);



/* =========================================================
VIEW: vw_customer_performance
PURPOSE:
	Provides a summarized performance overview for each customer.

DESCRIPTION:
	- Shows total number of loads handled per customer.
	- Calculates total revenue generated by each customer.
	- Computes the average revenue per load.
	- Includes all customers even if they have no loads (LEFT JOIN).

USE CASES:
	- Customer profitability analysis
	- Sales performance reporting
	- Identifying high-value customers
========================================================= */
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

/* =========================================================
VIEW: vw_driver_performance
PURPOSE:
	Tracks yearly productivity and efficiency of drivers.

DESCRIPTION:
	- Displays driver full name and ID.
	- Aggregates total loads handled per year.
	- Calculates total miles driven annually.
	- Computes average fuel efficiency (MPG).
	- Excludes trips with missing dispatch dates.

USE CASES:
	- Driver performance evaluation
	- Productivity reporting
	- Fuel efficiency monitoring
========================================================= */
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


/* =========================================================
VIEW: vw_delivery_performance
PURPOSE:
	Measures on-time delivery performance of drivers.

DESCRIPTION:
	- Shows yearly delivery statistics for each driver.
	- Counts total delivery stops.
	- Calculates number of on-time stops.
	- Computes on-time delivery percentage KPI.

USE CASES:
	- Service level monitoring
	- Driver KPI tracking
	- Operational performance dashboards
========================================================= */
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


/* =========================================================
VIEW: vw_fuel_efficiency
PURPOSE:
	Provides fuel consumption and cost analytics by truck.

DESCRIPTION:
	- Summarizes annual fuel usage per truck.
	- Calculates total gallons consumed.
	- Computes total fuel spending.
	- Shows average fuel price per gallon.
	- Includes truck tank capacity information.

USE CASES:
	- Fuel cost analysis
	- Fleet efficiency monitoring
	- Budget planning
========================================================= */
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


/* =========================================================
VIEW: vw_truck_maintenance_cost
PURPOSE:
	Analyzes safety incidents and associated vehicle damage costs.

DESCRIPTION:
	- Displays incidents grouped by driver, truck, and year.
	- Counts total incidents.
	- Calculates average damage cost per incident.
	- Helps identify high-risk drivers or vehicles.

USE CASES:
	- Risk management reporting
	- Safety performance tracking
	- Maintenance cost analysis
========================================================= */
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

/* =========================================================
VIEW: vw_customer_loads
PURPOSE:
	Provides detailed load-level information for each customer.

DESCRIPTION:
	- Lists all loads associated with each customer.
	- Includes load details such as type, weight, and revenue.
	- Calculates additional charges (fuel surcharge + accessorial).

USE CASES:
	- Customer billing review
	- Load history reporting
	- Revenue breakdown analysis
========================================================= */
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

/* =========================================================
VIEW: vw_driver_loads
PURPOSE:
	Provides comprehensive trip and load details for drivers.

DESCRIPTION:
	- Shows driver, truck, and trailer information.
	- Includes trip metrics (distance, duration, idle time).
	- Displays load type and piece count.
	- Useful for operational tracking and auditing.

USE CASES:
	- Driver activity reports
	- Fleet utilization analysis
	- Operational monitoring
========================================================= */
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

/* =========================================================
VIEW: vw_load_trip
PURPOSE:
	Combines load and route information for logistics analysis.

DESCRIPTION:
	- Displays load shipment details.
	- Includes origin and destination locations.
	- Shows expected route distance.
	- Helps analyze shipment patterns and route efficiency.

USE CASES:
	- Route planning analysis
	- Shipment tracking reports
	- Logistics optimization
========================================================= */
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

-- =========================================================
-- Function: Capitalize
-- Purpose:
--   Standardizes text formatting by:
--   • Removing leading and trailing spaces
--   • Collapsing multiple spaces into a single space
--   • Capitalizing the first letter of each word
--   • Converting all other letters to lowercase
--
-- Behavior:
--   Example:
--     '   jOhN    DOE  '  →  'John Doe'
--
-- Returns:
--   Formatted string with proper capitalization
--
-- Notes:
--   Deterministic function (same input → same output)
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

    -- Handle NULL input
    IF input IS NULL THEN
        RETURN NULL;
    END IF;

    SET in_string = TRIM(input);

    -- Handle empty string
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



-- =========================================================
-- Trigger: new_customer
-- Purpose:
--   Automatically formats the customer_name field before
--   inserting a new record into the customers table.
--   Ensures consistent capitalization for free-text input.
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
--   • Capitalizing names and free-text fields
--   • Converting license/state codes to uppercase
--   • Removing leading/trailing spaces
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
--   • Standardizes driver data before updates
--   • Automatically sets employment status to "Terminated"
--   • when a termination_date is newly provided
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
--   by capitalizing names and uppercasing state codes.
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
--   Ensures consistent formatting of trailers fields
--   by capitalizing trailer type, status, current_location values before insertion.
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
--   capitalizing make and home terminal fields.
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
--   • Standardizes trip status formatting
--   • Automatically calculates average MPG
--   • Prevents division by zero errors
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
--   determines whether a delivery was on time.
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
--   • Standardizes fuel purchase location formatting
--   • Automatically calculates total fuel cost
--   • Handles NULL values safely
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
--   • Standardizes incident location and type formatting
--   • Converts boolean-like text values into proper
--     numeric boolean flags (0 or 1)
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

-- ============================
-- Indexes for performance
-- Improve search, filtering, and join efficiency
-- ============================
CREATE INDEX `customer_name_INDEX` ON customers(customer_name);
CREATE INDEX `customer_type_INDEX` ON customers(customer_type);

CREATE INDEX `driver_first_name_INDEX` ON drivers(first_name);
CREATE INDEX `driver_last_name_INDEX` ON drivers(last_name);
CREATE INDEX `driver_name_INDEX` ON drivers(first_name, last_name);

CREATE INDEX `facility_name_INDEX` ON facilities(facility_name);
CREATE INDEX `facility_type_INDEX` ON facilities(facility_type);

CREATE INDEX `trailer_number_INDEX` ON trailers(trailer_number);
CREATE INDEX `trailer_type_INDEX` ON trailers(trailer_type);

CREATE INDEX `truck_unit_number_INDEX` ON trucks(unit_number);
CREATE INDEX `truck_make_INDEX` ON trucks(make);
CREATE INDEX `tank_capacity_gallons_INDEX` ON trucks(tank_capacity_gallons);



LOAD DATA LOCAL INFILE 'C:/Users/Mohamed/Documents/Data Analysis Path/CS50s Introduction to Databases with SQL/Final Project/datasets/customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
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

LOAD DATA LOCAL INFILE 'C:/Users/Mohamed/Documents/Data Analysis Path/CS50s Introduction to Databases with SQL/Final Project/datasets/drivers.csv'
INTO TABLE drivers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
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

LOAD DATA LOCAL INFILE 'C:/Users/Mohamed/Documents/Data Analysis Path/CS50s Introduction to Databases with SQL/Final Project/datasets/facilities.csv'
INTO TABLE facilities
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/Users/Mohamed/Documents/Data Analysis Path/CS50s Introduction to Databases with SQL/Final Project/datasets/routes.csv'
INTO TABLE routes
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/Users/Mohamed/Documents/Data Analysis Path/CS50s Introduction to Databases with SQL/Final Project/datasets/loads.csv'
INTO TABLE loads
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/Users/Mohamed/Documents/Data Analysis Path/CS50s Introduction to Databases with SQL/Final Project/datasets/trailers.csv'
INTO TABLE trailers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
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

LOAD DATA LOCAL INFILE 'C:/Users/Mohamed/Documents/Data Analysis Path/CS50s Introduction to Databases with SQL/Final Project/datasets/trucks.csv'
INTO TABLE trucks
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
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

-- Records: 85410  Deleted: 0  Skipped: 4952  Warnings: 4952
LOAD DATA LOCAL INFILE 'C:/Users/Mohamed/Documents/Data Analysis Path/CS50s Introduction to Databases with SQL/Final Project/datasets/trips.csv'
INTO TABLE trips
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
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

-- Records: 170820  Deleted: 0  Skipped: 9904  Warnings: 351544
LOAD DATA LOCAL INFILE 'C:/Users/Mohamed/Documents/Data Analysis Path/CS50s Introduction to Databases with SQL/Final Project/datasets/delivery_events.csv'
INTO TABLE delivery_events
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS(
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

-- Records: 196442  Deleted: 0  Skipped: 11391  Warnings: 11391
LOAD DATA LOCAL INFILE 'C:/Users/Mohamed/Documents/Data Analysis Path/CS50s Introduction to Databases with SQL/Final Project/datasets/fuel_purchases.csv'
INTO TABLE fuel_purchases
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
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

-- Records: 170  Deleted: 0  Skipped: 5  Warnings: 515
LOAD DATA LOCAL INFILE 'C:/Users/Mohamed/Documents/Data Analysis Path/CS50s Introduction to Databases with SQL/Final Project/datasets/safety_incidents.csv'
INTO TABLE safety_incidents
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
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

-- Records: 2920  Deleted: 0  Skipped: 0  Warnings: 0
LOAD DATA LOCAL INFILE 'C:/Users/Mohamed/Documents/Data Analysis Path/CS50s Introduction to Databases with SQL/Final Project/datasets/maintenance_records.csv'
INTO TABLE `maintenance_records`
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
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
