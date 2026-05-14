-- ============================================================
-- FILE: 01_connect.sql
-- PURPOSE:
--   Establishes a connection to the MySQL server and initializes
--   the logistics schema. This file must be executed first before
--   any other scripts in the pipeline.
--
-- REQUIREMENTS:
--   - MySQL server must be running and accessible
--   - The executing user must have CREATE, DROP, and USE privileges
--   - Local infile must be enabled on both client and server:
--       Client flag : --local-infile=1
--       Server flag : SET GLOBAL local_infile = 1;
--
-- ============================================================

-- USAGE (command line):
mysql -u root --local-infile=1

-- Enable local infile loading on the server side
SET GLOBAL local_infile = 1;

-- Drop the schema if it already exists (for clean re-runs)
DROP SCHEMA IF EXISTS `logistics`;

-- Create and select the logistics schema
CREATE SCHEMA IF NOT EXISTS `logistics`;
USE `logistics`;
