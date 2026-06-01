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

Los scripts SQL dentro de la carpeta `sql/` deben ser ejecutados de manera secuencial estricta:

1.  **`sql/01_bronze/01_raw_ingestion.sql`**: Inicializa la infraestructura de la base de datos, esquemas de aislamiento y los formatos de parseo nativos.
2.  **`sql/02_silver/02_canonical_model.sql`**: Construye el modelo físico canónico de producción (Silver layer).
3.  **`sql/03_transformations/03_load_customers.sql`**: Ingesta, limpia por Regex y homologa las dimensiones de clientes.
4.  **`sql/03_transformations/04_flatten_xml.sql`**: Procesa el aplanamiento multicapa de las transacciones XML eliminando duplicados financieros.
5.  **`sql/03_transformations/05_flatten_json.sql`**: Decodifica las transacciones anidadas del flujo JSON unificándolas bajo la tabla de hechos.
