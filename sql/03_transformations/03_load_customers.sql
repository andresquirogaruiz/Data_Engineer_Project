-- ============================================================================
-- TRANSFORMATION DML: INGESTA, LIMPIEZA REGEX Y HOMOLOGACIÓN DE CLIENTES
-- ============================================================================

USE SCHEMA NUAAV_PROB_DB.SILVER;

INSERT INTO silver.dim_customers (customer_key, first_name, last_name, email, customer_segment, is_active, client_source)
SELECT 
    TRIM(customer_id) as customer_key,
    TRIM(first_name) as first_name,
    TRIM(last_name) as last_name,
    -- Validación estricta de estructura de correo electrónico
    CASE WHEN REGEXP_LIKE(TRIM(email), '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$') THEN TRIM(email) ELSE NULL END as email,
    UPPER(COALESCE(NULLIF(TRIM(loyalty_tier), ''), 'STANDARD')) as customer_segment,
    TO_BOOLEAN(SPLIT_PART(TRIM(is_active), ' ', 1)) as is_active, -- Limpia comentarios inline del CSV
    'CLIENT_A_CSV' as client_source
FROM NUAAV_PROB_DB.BRONZE.raw_client_a_customers
WHERE customer_id IS NOT NULL AND customer_id <> ''
UNION ALL
SELECT 
    TRIM(customer_id) as customer_key,
    SPLIT_PART(TRIM(customer_name), ' ', 1) as first_name,
    SPLIT_PART(TRIM(customer_name), ' ', 2) as last_name,
    CASE WHEN REGEXP_LIKE(TRIM(email), '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$') THEN TRIM(email) ELSE NULL END as email,
    UPPER(TRIM(segment)) as customer_segment,
    TO_BOOLEAN(TRIM(is_active)) as is_active,
    'CLIENT_C_CSV' as client_source
FROM NUAAV_PROB_DB.BRONZE.raw_client_c_customers
WHERE customer_id IS NOT NULL AND customer_id <> '' AND customer_name <> 'Unknown User';
