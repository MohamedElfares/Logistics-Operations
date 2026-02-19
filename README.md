## 📚 Dataset Source

Rodriguez, Yogape. (2025). *Synthetic Logistics Operations Database (2022–2024).*  
Kaggle.  
https://www.kaggle.com/datasets/yogape/logistics-operations-database



# 🚚 Logistics Operations Database

## 📌 Overview

This project implements a **relational database system for a transportation & logistics company**. It models the full lifecycle of freight operations — from customer contracts and shipment planning to trip execution, fuel usage, maintenance, and safety incidents.

The system is designed to support:

* Operational tracking
* Financial analysis
* Performance optimization
* Risk monitoring
* Strategic planning

The database structure follows **normalized relational design principles** to ensure scalability, data integrity, and analytical flexibility.

---

# 🎯 Purpose of the Database

Modern logistics operations generate complex interconnected data across many domains:

* Fleet management
* Driver workforce management
* Shipment planning
* Fuel & maintenance costs
* Safety monitoring
* Customer revenue tracking

This database centralizes all operational data to enable:

✅ End-to-end trip visibility
✅ Cost and profitability analysis
✅ Operational performance tracking
✅ Safety & compliance monitoring
✅ Strategic decision support

---

# 🏢 Business Scope

The system models a **mid-to-large trucking logistics company** operating across multiple regions.

It captures:

## Core Operational Domains

### 1. Customer & Revenue Management

Tracks customers, contracts, freight types, and revenue potential.

### 2. Fleet Management

Manages trucks, trailers, fuel usage, and maintenance records.

### 3. Workforce Management

Tracks driver employment, licensing, experience, and assignments.

### 4. Shipment & Route Planning

Handles loads, routes, trip scheduling, and delivery events.

### 5. Cost & Risk Monitoring

Captures fuel purchases, maintenance costs, and safety incidents.

---

# 🧱 Database Architecture

## Entity Relationship Model

The system follows a **hub-and-spoke architecture** centered around the **Trip** entity.

```
Customers → Loads → Trips ← Drivers
                            ← Trucks
                            ← Trailers
```

Trips connect operational, financial, and safety data.

---

# 🗂️ Core Tables and Their Roles

---

## 👥 Customers

Stores client master data and revenue attributes.

**Purpose:**

* Manage customer segmentation
* Track contract types
* Support revenue forecasting

```
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
```

---

## 🚛 Trucks

Represents fleet assets and operational status.

**Used for:**

* Fleet tracking
* Maintenance scheduling
* Capacity planning

```
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
```

---

## 🚚 Trailers

Stores trailer specifications and availability.

**Supports:**

* Equipment allocation
* Freight compatibility matching

```
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
```

---

## 🧑‍✈️ Drivers

Captures workforce data including employment and licensing.

**Enables:**

* Driver utilization analysis
* Compliance tracking
* Safety performance evaluation

```
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
```

---

## 📦 Loads

Represents individual freight shipments.

Key attributes include:

* Customer ownership
* Weight and cargo type
* Revenue and surcharges

```
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
```

---

## 🛣️ Routes

Defines standard transportation corridors.

Supports:

* Distance estimation
* Pricing models
* Transit time predictions

```
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
```

---

## 🧭 Trips (Central Table)

The **core operational entity** linking:

* Driver
* Truck
* Trailer
* Load

Tracks performance metrics such as:

* Distance traveled
* Fuel consumed
* Driving hours
* Idle time

```
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
```

---

## ⛽ Fuel Purchases

Tracks fuel spending per trip.

Enables:

* Cost monitoring
* Fuel efficiency analysis
* Fraud detection

```SQL
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
```

---

## 🔧 Maintenance Records

Captures vehicle servicing and repair costs.

Supports:

* Preventive maintenance planning
* Lifecycle cost analysis
* Downtime tracking

```SQL
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
```

---

## 🚚 Delivery Events

Logs pickup and delivery operations.

Used for:

* On-time performance analysis
* Detention time monitoring
* Customer service metrics

```SQL
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
```

---

## ⚠️ Safety Incidents

Tracks accidents and safety violations.

Supports:

* Risk management
* Insurance claims analysis
* Driver safety scoring

```SQL
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
```

---

## 🏭 Facilities

Stores warehouse, terminal, and distribution center data.

Used for:

* Logistics network analysis
* Operational planning

```SQL
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
```

---

# 🔗 Relationships Overview

| Relationship         | Description                     |
| -------------------- | ------------------------------- |
| Customer → Loads     | Customers own shipments         |
| Load → Trips         | Loads are transported via trips |
| Trip → Driver        | Drivers execute trips           |
| Trip → Truck/Trailer | Equipment assigned to trips     |
| Trip → Fuel          | Fuel costs tied to trips        |
| Trip → Safety        | Incidents linked to trips       |
| Truck → Maintenance  | Vehicles have service history   |

![ER Diagram](diagram.png)

---

# 📊 Key Use Cases

---

## Operational Use Cases

### 📍 Trip Monitoring

* Track real-time performance
* Identify delays and bottlenecks

### 🚚 Fleet Utilization

* Measure asset usage rates
* Optimize dispatching

### 🧑‍✈️ Driver Performance

* Evaluate productivity
* Monitor safety records

---

## Financial Use Cases

### 💰 Cost Analysis

* Fuel consumption trends
* Maintenance spending patterns

### 📈 Profitability Tracking

* Revenue per load
* Cost per mile

---

## Risk & Compliance Use Cases

### ⚠️ Safety Monitoring

* Incident frequency tracking
* Risk hotspot analysis

### 📋 Regulatory Compliance

* Driver license tracking
* Maintenance history audits

---

# 📊 Analytical Capabilities

The database supports advanced business intelligence queries such as:

* ### Fuel efficiency by truck
```SQL
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
```

* ### Driver productivity metrics
```SQL
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
```

* ### Route profitability analysis
```SQL
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
```

* ### Maintenance cost trends
```SQL
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
```

* ### Customer revenue segmentation
```SQL
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
```

---

# ⚙️ Optimization Strategies

The design incorporates:

### Normalization

* Eliminates redundancy
* Improves data integrity

### Strong Referential Integrity

* Foreign key constraints
* Controlled ENUM values

### Performance Considerations

* Surrogate primary keys
* Index-friendly schema
* Modular entity separation

---

# 🚧 Limitations

While robust, the system has some constraints:

## 1. No Real-Time Tracking

Does not support GPS or telematics streaming data.

## 2. Limited Historical Versioning

Changes to assets or contracts overwrite previous states.

## 3. Geographic Simplicity

Uses city/state rather than full geospatial modeling.

## 4. No Scheduling Optimization Engine

Route optimization must be handled externally.

---

# 🚀 Potential Future Enhancements

Possible improvements include:

* Real-time telematics integration
* Predictive maintenance analytics
* AI-based route optimization
* Driver safety scoring models
* Dynamic pricing engine

---

# 🏁 Conclusion

This database provides a **comprehensive operational foundation** for logistics companies by integrating:

* Operational tracking
* Financial insights
* Risk monitoring
* Performance analytics

Its modular, normalized design ensures it can scale into an enterprise-grade logistics intelligence platform.
