# Financial Data Ingestion & Canonical Modeling Pipeline (Snowflake)

Este repositorio contiene la solución completa de arquitectura e ingeniería de datos para procesar flujos financieros multidestino (CSV, XML y JSON) utilizando exclusivamente capacidades nativas de **Snowflake SQL**. 

El proyecto adopta un enfoque moderno de **Arquitectura Medallón** enfocado en el desacoplamiento de capas de almacenamiento, la resiliencia estructural (*Schema Drift*) y la remediación analítica de la calidad del dato.

## Estructura del Repositorio

* **`data/sample_data/`**: Directorio reservado para el almacenamiento temporal local de las fuentes crudas.
* **`docs/`**: Documentación técnica detallada sobre la arquitectura del pipeline y la bitácora de remediación de anomalías.
* **`sql/01_bronze/`**: Definición de objetos base, File Formats de parsing y tablas laxas de aterrizaje raw (`VARCHAR` / `VARIANT`).
* **`sql/02_silver/`**: Modelo relacional canónico unificado estructurado bajo esquema de Hechos y Dimensiones con tipado fuerte.
* **`sql/03_transformations/`**: Pipelines modulares de transformación DML, de-duplicación analítica y aplanamiento jerárquico.

## Secuencia de Despliegue y Ejecución en Snowflake

Los scripts SQL dentro de la carpeta `sql/` deben ser ejecutados de manera secuencial:

1.  **`sql/01_bronze/01_raw_ingestion.sql`**: Inicializa la infraestructura de la base de datos, esquemas de aislamiento y los formatos de parseo nativos.
2.  **Subir archivos reales a Snowflake (Carga al Stage):**
    Abre tu terminal y ejecuta los comandos `PUT` usando **SnowSQL CLI** para transferir los archivos locales reales desde `docs/Data to loadx` al Stage interno de Snowflake:
    ```sql
    -- Iniciar SnowSQL y conectarse a tu cuenta
    snowsql -a <identificador_cuenta> -u <usuario>

    -- Ejecutar comandos PUT para subir archivos
    PUT 'file://E:/Users/andres.qr/Documents/Data_Engineer_Project/docs/Data to loadx/Customer.csv' @project_stage AUTO_COMPRESS=TRUE;
    PUT 'file://E:/Users/andres.qr/Documents/Data_Engineer_Project/docs/Data to loadx/Orders.csv' @project_stage AUTO_COMPRESS=TRUE;
    PUT 'file://E:/Users/andres.qr/Documents/Data_Engineer_Project/docs/Data to loadx/Products.csv' @project_stage AUTO_COMPRESS=TRUE;
    
    PUT 'file://E:/Users/andres.qr/Documents/Data_Engineer_Project/docs/Data to loadx/Client B/Customer.CSV' @project_stage/client_b/ AUTO_COMPRESS=TRUE;
    PUT 'file://E:/Users/andres.qr/Documents/Data_Engineer_Project/docs/Data to loadx/Client B/Order.csv' @project_stage/client_b/ AUTO_COMPRESS=TRUE;
    PUT 'file://E:/Users/andres.qr/Documents/Data_Engineer_Project/docs/Data to loadx/Client B/Product.csv' @project_stage/client_b/ AUTO_COMPRESS=TRUE;
    PUT 'file://E:/Users/andres.qr/Documents/Data_Engineer_Project/docs/Data to loadx/Client B/Payments.csv' @project_stage/client_b/ AUTO_COMPRESS=TRUE;
    
    PUT 'file://E:/Users/andres.qr/Documents/Data_Engineer_Project/docs/Data to loadx/ClientA_Transactions_*.xml' @project_stage/xml/ AUTO_COMPRESS=TRUE;
    PUT 'file://E:/Users/andres.qr/Documents/Data_Engineer_Project/docs/Data to loadx/ClientA_Transactions_4.txt' @project_stage/xml/ AUTO_COMPRESS=TRUE;
    
    PUT 'file://E:/Users/andres.qr/Documents/Data_Engineer_Project/docs/Data to loadx/Client B/transactions.json' @project_stage/json/ AUTO_COMPRESS=TRUE;
    ```
3.  **`sql/01_bronze/01.5_load_bronze.sql`**: Ejecuta los comandos `COPY INTO` e ingestas avanzadas para preprocesar y limpiar
4.  **`sql/02_silver/02_canonical_model.sql`**: Construye el modelo físico canónico de producción (Silver layer).
5.  **`sql/03_transformations/03_load_customers.sql`**: Ingesta, limpia por Regex y homologa las dimensiones de clientes.
6.  **`sql/03_transformations/04_flatten_xml.sql`**: Procesa el aplanamiento de transacciones XML jerárquicas y elimina duplicados financieros.
7.  **`sql/03_transformations/05_flatten_json.sql`**: Decodifica las transacciones anidadas del flujo JSON unificándolas bajo la tabla de hechos final.
