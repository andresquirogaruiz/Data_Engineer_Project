-- ============================================================================
-- TRANSFORMATION DML: PARSING Y EXTRACCIÓN SEMIESTRUCTURADA JSON ANIDADO
-- ============================================================================

USE SCHEMA NUAAV_PROB_DB.SILVER;

INSERT INTO silver.fact_transactions (transaction_id, order_id, customer_key, sku, order_date, quantity, unit_price, total_amount, currency, payment_method, transaction_status, client_source)
WITH json_stage_one AS (
    SELECT
        -- Acceso por notación de puntos nativa sobre objetos Variant de Snowflake
        t.value:id::VARCHAR as transaction_id,
        COALESCE(t.value:order.id::VARCHAR, 'UNKNOWN_ORD') as order_id,
        COALESCE(t.value:order.customer.id::VARCHAR, 'UNKNOWN_CUST') as customer_key,
        COALESCE(NULLIF(t.value:order.date::VARCHAR, ''), '1900-01-01')::DATE as order_date,
        i.value:sku::VARCHAR as sku,
        ABS(i.value:qty::INT) as quantity, -- Remediación de cantidades negativas
        ABS(i.value:price.amount::NUMBER(10,2)) as unit_price,
        ABS(t.value:payment.total::NUMBER(10,2)) as total_amount,
        COALESCE(i.value:price.currency::VARCHAR, 'USD') as currency,
        COALESCE(t.value:payment.method::VARCHAR, 'UNKNOWN') as payment_method,
        'COMPLETED' as transaction_status
    FROM NUAAV_PROB_DB.BRONZE.raw_transactions_json,
    LATERAL FLATTEN(input => raw_data:transactions) t, -- Rompe el arreglo maestro de transacciones
    LATERAL FLATTEN(input => t.value:items) i         -- Rompe el sub-arreglo embebido de ítems
)
SELECT * FROM json_stage_one
QUALIFY ROW_NUMBER() OVER (PARTITION BY transaction_id, sku ORDER BY total_amount DESC) = 1; -- Garantiza unicidad relacional
