-- ============================================================================
-- ARQUITECTURA MEDALLÓN: MODELO CANÓNICO UNIFICADO (CAPA SILVER)
-- ============================================================================

USE SCHEMA NUAAV_PROB_DB.SILVER;

-- Dimensión Maestra de Clientes Homologada
CREATE OR REPLACE TABLE silver.dim_customers (
    customer_key VARCHAR PRIMARY KEY,
    first_name VARCHAR,
    last_name VARCHAR,
    email VARCHAR,
    customer_segment VARCHAR, 
    is_active BOOLEAN,
    client_source VARCHAR
);

-- Dimensión Maestra de Productos
CREATE OR REPLACE TABLE silver.dim_products (
    sku VARCHAR PRIMARY KEY,
    product_name VARCHAR,
    category VARCHAR,
    unit_price NUMBER(10,2),
    currency VARCHAR(3),
    client_source VARCHAR
);

-- Tabla de Hechos Central de Transacciones Financieras
CREATE OR REPLACE TABLE silver.fact_transactions (
    transaction_id VARCHAR,
    order_id VARCHAR,
    customer_key VARCHAR,
    sku VARCHAR,
    order_date DATE,
    quantity INT,
    unit_price NUMBER(10,2),
    total_amount NUMBER(10,2),
    currency VARCHAR(3),
    payment_method VARCHAR,
    transaction_status VARCHAR,
    client_source VARCHAR,
    processed_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
