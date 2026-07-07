-- =============================================================================
-- PostgreSQL Initialization Script
-- Runs automatically on first container start via /docker-entrypoint-initdb.d
-- =============================================================================

-- Database for Apache Superset metadata
CREATE DATABASE superset_db;

-- Grant all privileges to the postgres user on superset database
GRANT ALL PRIVILEGES ON DATABASE superset_db TO postgres;
