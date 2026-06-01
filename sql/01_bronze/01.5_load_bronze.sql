-- ============================================================================
-- ARQUITECTURA MEDALLÓN: INGESTA Y PREPROCESAMIENTO AVANZADO (SQL-ONLY)
-- ============================================================================

USE SCHEMA NUAAV_PROB_DB.BRONZE;

-- 1. CREACIÓN DEL STAGE INTERNO DE PROYECTO
-- Este stage almacenará de manera temporal los archivos locales subidos por SnowSQL
CREATE OR REPLACE STAGE project_stage;

-- 2. FILE FORMATS: Reglas de extracción con soporte para pre-procesamiento
-- Formato CSV que omite los encabezados no estándar (banners de inicio/fin)
CREATE OR REPLACE FILE FORMAT csv_format_with_banner
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 2 -- Omite la línea de banner "----- START OF FILE" y la línea de encabezados
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    EMPTY_FIELD_AS_NULL = TRUE
    NULL_IF = ('', 'NULL', 'null', 'UNKNOWN');

-- Formato de texto línea por línea (usado para preprocesar JSON y XML complejos con SQL)
CREATE OR REPLACE FILE FORMAT line_by_line_format
    TYPE = 'CSV'
    FIELD_DELIMITER = NONE
    RECORD_DELIMITER = '\n'
    ESCAPE_UNENCLOSED_FIELD = NONE;

-- ============================================================================
-- DOCUMENTACIÓN DE COMANDOS PUT (Efectuar en SnowSQL CLI localmente)
-- ============================================================================
-- Para subir los archivos a tu Stage en Snowflake, abre SnowSQL y ejecuta:
--
-- PUT 'file://E:/Users/andres.qr/Documents/Data_Engineer_Project/docs/Data to loadx/Customer.csv' @project_stage AUTO_COMPRESS=TRUE;
-- PUT 'file://E:/Users/andres.qr/Documents/Data_Engineer_Project/docs/Data to loadx/Orders.csv' @project_stage AUTO_COMPRESS=TRUE;
-- PUT 'file://E:/Users/andres.qr/Documents/Data_Engineer_Project/docs/Data to loadx/Products.csv' @project_stage AUTO_COMPRESS=TRUE;
--
-- PUT 'file://E:/Users/andres.qr/Documents/Data_Engineer_Project/docs/Data to loadx/Client B/Customer.CSV' @project_stage/client_b/ AUTO_COMPRESS=TRUE;
-- PUT 'file://E:/Users/andres.qr/Documents/Data_Engineer_Project/docs/Data to loadx/Client B/Order.csv' @project_stage/client_b/ AUTO_COMPRESS=TRUE;
-- PUT 'file://E:/Users/andres.qr/Documents/Data_Engineer_Project/docs/Data to loadx/Client B/Product.csv' @project_stage/client_b/ AUTO_COMPRESS=TRUE;
-- PUT 'file://E:/Users/andres.qr/Documents/Data_Engineer_Project/docs/Data to loadx/Client B/Payments.csv' @project_stage/client_b/ AUTO_COMPRESS=TRUE;
--
-- PUT 'file://E:/Users/andres.qr/Documents/Data_Engineer_Project/docs/Data to loadx/ClientA_Transactions_*.xml' @project_stage/xml/ AUTO_COMPRESS=TRUE;
-- PUT 'file://E:/Users/andres.qr/Documents/Data_Engineer_Project/docs/Data to loadx/ClientA_Transactions_4.txt' @project_stage/xml/ AUTO_COMPRESS=TRUE;
--
-- PUT 'file://E:/Users/andres.qr/Documents/Data_Engineer_Project/docs/Data to loadx/Client B/transactions.json' @project_stage/json/ AUTO_COMPRESS=TRUE;
-- ============================================================================


-- ============================================================================
-- 3. CARGA DE ARCHIVOS CSV (CLIENTE A y CLIENTE C / B)
-- ============================================================================

-- Cliente A: Clientes (Customer.csv)
COPY INTO bronze.raw_client_a_customers
FROM (
    SELECT $1, $2, $3, $4, $5, $6, $7
    FROM @project_stage/Customer.csv
)
FILE_FORMAT = csv_format_with_banner
ON_ERROR = 'CONTINUE';

-- Cliente A: Órdenes (Orders.csv)
COPY INTO bronze.raw_client_a_orders
FROM (
    SELECT $1, $2, $3, $4, $5
    FROM @project_stage/Orders.csv
)
FILE_FORMAT = csv_format_with_banner
ON_ERROR = 'CONTINUE';

-- Cliente A: Productos (Products.csv)
COPY INTO bronze.raw_client_a_products
FROM (
    SELECT $1, $2, $3, $4, $5, $6
    FROM @project_stage/Products.csv
)
FILE_FORMAT = csv_format_with_banner
ON_ERROR = 'CONTINUE';

-- Cliente C (Client B): Clientes (Customer.CSV)
COPY INTO bronze.raw_client_c_customers
FROM (
    SELECT $1, $2, $3, $4, $5
    FROM @project_stage/client_b/Customer.CSV
)
FILE_FORMAT = csv_format_with_banner
ON_ERROR = 'CONTINUE';

-- Cliente C (Client B): Órdenes (Order.csv)
COPY INTO bronze.raw_client_c_orders
FROM (
    SELECT $1, $2, $3, $4
    FROM @project_stage/client_b/Order.csv
)
FILE_FORMAT = csv_format_with_banner
ON_ERROR = 'CONTINUE';

-- Cliente C (Client B): Productos (Product.csv)
COPY INTO bronze.raw_client_c_products
FROM (
    SELECT $1, $2, $3, $4, $5, $6
    FROM @project_stage/client_b/Product.csv
)
FILE_FORMAT = csv_format_with_banner
ON_ERROR = 'CONTINUE';

-- Cliente C (Client B): Pagos (Payments.csv)
COPY INTO bronze.raw_client_c_payments
FROM (
    SELECT $1, $2, $3, $4, $5, $6
    FROM @project_stage/client_b/Payments.csv
)
FILE_FORMAT = csv_format_with_banner
ON_ERROR = 'CONTINUE';


-- ============================================================================
-- 4. CARGA DE ARCHIVOS XML JERÁRQUICOS (CLIENTE A)
-- preprocesamiento SQL: Eliminación de banners de texto y Parseo XML nativo
-- ============================================================================

INSERT INTO bronze.raw_transactions_xml (raw_data, file_name)
WITH cleaned_xml_lines AS (
    SELECT 
        METADATA$FILENAME as file_name,
        METADATA$FILE_ROW_NUMBER as line_num,
        $1 as clean_line
    FROM @project_stage/xml/
    (FILE_FORMAT => line_by_line_format)
    WHERE $1 NOT LIKE '----- START%'
      AND $1 NOT LIKE '----- END%'
      AND $1 IS NOT NULL
      AND TRIM($1) != ''
)
SELECT 
    PARSE_XML(LISTAGG(clean_line, '\n') WITHIN GROUP (ORDER BY line_num)) as raw_data,
    file_name
FROM cleaned_xml_lines
GROUP BY file_name;


-- ============================================================================
-- 5. CARGA DE ARCHIVO JSON ANIDADO CON COMENTARIOS (CLIENTE C)
-- preprocesamiento SQL: Eliminación de banners y comentarios inline "//"
-- ============================================================================

INSERT INTO bronze.raw_transactions_json (raw_data, file_name)
WITH cleaned_json_lines AS (
    SELECT 
        METADATA$FILENAME as file_name,
        METADATA$FILE_ROW_NUMBER as line_num,
        REGEXP_REPLACE($1, '//.*$', '') as clean_line -- Elimina comentarios inline "//"
    FROM @project_stage/json/transactions.json
    (FILE_FORMAT => line_by_line_format)
    WHERE $1 NOT LIKE '----- START%'
      AND $1 NOT LIKE '----- END%'
      AND $1 IS NOT NULL
)
SELECT 
    PARSE_JSON(LISTAGG(clean_line, '\n') WITHIN GROUP (ORDER BY line_num)) as raw_data,
    file_name
FROM cleaned_json_lines
GROUP BY file_name;
