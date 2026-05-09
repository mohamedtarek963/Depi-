/*
========================================================================
OULAD DATA WAREHOUSE SETUP
========================================================================
Script Purpose:
This script initializes the core architecture for the OULAD Data Warehouse
project. It performs the following actions:
1. Checks for the existence of 'oulad_warehouse' database.
2. Drops the existing database to ensure a clean state (Destructive Action).
3. Creates a fresh 'oulad_warehouse' database.
4. Sets up the Medallion Architecture schemas:
   - Bronze: For raw, unmodified data.
   - Silver: For cleansed and processed data.
   - Gold: For final analytical (Star Schema) data.

WARNING:
This script contains destructive operations. If a database named
'oulad_warehouse' already exists, it will be permanently deleted along with
all tables, views, and data contained within. Please ensure you have 
proper backups before executing.
========================================================================
*/

USE master;
GO

-- Check if the database exists; if so, disconnect users and drop it for a fresh start--
IF EXISTS (SELECT 1 FROM sys.databases WHERE NAME = 'oulad_warehouse')
BEGIN
	ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE DataWarehouse;
END;
GO



-- Create_OULAD_DATA_WareHouse --
Create DATABASE oulad_warehouse;
GO

USE oulad_warehouse;
GO

-- Create Medallion Architecture Schemas for data organization --

CREATE SCHEMA Bronze;
GO
CREATE SCHEMA Silver;
GO
CREATE SCHEMA Gold;
GO