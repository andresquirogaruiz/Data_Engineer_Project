-- ============================================================================
-- ARQUITECTURA MEDALLÓN: CONFIGURACIÓN DE CAPA BRONZE (RAW)
-- ============================================================================

CREATE DATABASE IF NOT EXISTS NUAAV_PROB_DB;
CREATE SCHEMA IF NOT EXISTS NUAAV_PROB_DB.BRONZE;
CREATE SCHEMA IF NOT EXISTS NUAAV_PROB_DB.SILVER;

USE SCHEMA NUAAV_PROB_DB.BRONZE;

-- 1. FILE FORMATS: Reglas de extracción para fuentes heterogéneas
CREATE OR REPLACE FILE FORMAT csv_format
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    EMPTY_FIELD_AS_NULL = TRUE
    NULL_IF = ('', 'NULL', 'null', 'UNKNOWN');

CREATE OR REPLACE FILE FORMAT xml_format
    TYPE = 'XML'
    STRIP_OUTER_ELEMENT = FALSE
    PRESERVE_SPACE = FALSE;

CREATE OR REPLACE FILE FORMAT json_format
    TYPE = 'JSON'
    STRIP_OUTER_ARRAY = FALSE
    IGNORE_UTF8_ERRORS = TRUE;

-- 2. DDL BRONZE TABLES: Tablas de aterrizaje altamente permisivas (VARCHAR / VARIANT)
CREATE OR REPLACE TABLE bronze.raw_client_a_customers (customer_id VARCHAR, first_name VARCHAR, last_name VARCHAR, email VARCHAR, loyalty_tier VARCHAR, signup_source VARCHAR, is_active VARCHAR);
CREATE OR REPLACE TABLE bronze.raw_client_a_orders    (order_id VARCHAR, customer_id VARCHAR, order_date VARCHAR, order_status VARCHAR, channel VARCHAR);
CREATE OR REPLACE TABLE bronze.raw_client_a_products  (sku VARCHAR, product_name VARCHAR, category VARCHAR, unit_price VARCHAR, currency VARCHAR, is_active VARCHAR);

CREATE OR REPLACE TABLE bronze.raw_client_c_customers (customer_id VARCHAR, customer_name VARCHAR, email VARCHAR, segment VARCHAR, is_active VARCHAR);
CREATE OR REPLACE TABLE bronze.raw_client_c_orders    (order_id VARCHAR, customer_id VARCHAR, order_date VARCHAR, order_status VARCHAR);
CREATE OR REPLACE TABLE bronze.raw_client_c_products  (sku VARCHAR, product_name VARCHAR, category VARCHAR, unit_price VARCHAR, currency VARCHAR, is_active VARCHAR);
CREATE OR REPLACE TABLE bronze.raw_client_c_payments  (payment_id VARCHAR, order_id VARCHAR, payment_method VARCHAR, amount VARCHAR, currency VARCHAR, status VARCHAR);

CREATE OR REPLACE TABLE bronze.raw_transactions_xml (
    raw_data VARIANT,
    file_name VARCHAR,
    ingested_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE bronze.raw_transactions_json (
    raw_data VARIANT,
    file_name VARCHAR,
    ingested_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
