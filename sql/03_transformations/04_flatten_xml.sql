-- ============================================================================
-- TRANSFORMATION DML: APLANAMIENTO XML COMPLEJO Y MITIGACIÓN DE DUPLICADOS
-- ============================================================================

USE SCHEMA NUAAV_PROB_DB.SILVER;

INSERT INTO silver.fact_transactions (transaction_id, order_id, customer_key, sku, order_date, quantity, unit_price, total_amount, currency, payment_method, transaction_status, client_source)
WITH xml_stage_one AS (
    SELECT
        -- Extracción modular de nodos principales usando XMLGET
        XMLGET(t.value, 'TransactionID'):"$" :: VARCHAR as transaction_id,
        COALESCE(XMLGET(XMLGET(t.value, 'Order'), 'OrderID'):"$" :: VARCHAR, 'UNKNOWN_ORD') as order_id,
        COALESCE(NULLIF(XMLGET(XMLGET(t.value, 'Order'), 'OrderDate'):"$" :: VARCHAR, ''), '1900-01-01') as raw_date,
        XMLGET(XMLGET(XMLGET(t.value, 'Order'), 'Customer'), 'CustomerID'):"$" :: VARCHAR as customer_key,
        
        -- Extracción de montos absolutos mitigando negativos en origen
        ABS(TO_NUMBER(XMLGET(XMLGET(t.value, 'Payment'), 'Amount'):"$" :: VARCHAR, 10, 2)) as total_amount,
        COALESCE(XMLGET(XMLGET(t.value, 'Payment'), 'Amount'):"@currency" :: VARCHAR, 'USD') as currency,
        COALESCE(XMLGET(XMLGET(t.value, 'Payment'), 'Method'):"$" :: VARCHAR, 'UNKNOWN') as payment_method,
        
        -- Bloque jerárquico contenedor de artículos individuales
        XMLGET(t.value, 'Items') as items_node
    FROM NUAAV_PROB_DB.BRONZE.raw_transactions_xml,
    LATERAL FLATTEN(input => raw_data:"$") t -- Desagrega el nodo raíz SalesData
)
SELECT
    f.transaction_id,
    f.order_id,
    COALESCE(f.customer_key, 'UNKNOWN_CUST') as customer_key,
    XMLGET(i.value, 'SKU'):"$" :: VARCHAR as sku,
    TO_DATE(f.raw_date, 'YYYY-MM-DD') as order_date,
    ABS(XMLGET(i.value, 'Quantity'):"$" :: INT) as quantity, -- Remediación de cantidades negativas
    ABS(TO_NUMBER(XMLGET(XMLGET(i.value, 'UnitPrice'), '$')::VARCHAR, 10, 2)) as unit_price,
    f.total_amount,
    f.currency,
    f.payment_method,
    'COMPLETED' as transaction_status,
    'CLIENT_A_XML' as client_source
FROM xml_stage_one f,
LATERAL FLATTEN(input => f.items_node:"$") i -- Segundo aplanamiento para granularidad SKU
WHERE f.transaction_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY f.transaction_id, sku ORDER BY f.total_amount DESC) = 1; -- Deduplicación analítica
