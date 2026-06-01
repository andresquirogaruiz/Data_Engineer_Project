# Bitácora de Mitigación de Anomalías de Calidad de Datos

Durante el proceso de diseño de este pipeline de datos se identificaron e implementaron estrategias puras de SQL para resolver anomalías financieras críticas sin depender de cómputo externo:

### 1. Registros Duplicados en Ventas (`TXN-1041`, `C-TXN-3001`)
* **Problema:** Transacciones idénticas repetidas a lo largo de las particiones del JSON y XML.
* **Solución:** Uso de la cláusula nativa `QUALIFY ROW_NUMBER() OVER (PARTITION BY transaction_id, sku ORDER BY total_amount DESC) = 1`. 
* **Justificación:** Evita operaciones costosas de ordenamiento global (`DISTINCT`) procesando la de-duplicación eficientemente en las ventanas de memoria del cluster de Snowflake.

### 2. Magnitudes Métricas Negativas o Corruptas
* **Problema:** Precios unitarios y cantidades registradas erróneamente con valores negativos (ej. precios `-9.99` o cantidades `-2`).
* **Solución:** Aplicación de la función matemática de valor absoluto `ABS()`.
* **Justificación:** En analítica transaccional, los inputs negativos sin banderas explícitas de notas de crédito corresponden a fallos en sistemas origen y se normalizan a magnitudes absolutas para preservar la integridad del revenue calculable.

### 3. Contaminación por Comentarios Inline en CSV
* **Problema:** Cadenas de texto incrustadas al final de los registros como `true <-- negative price` o `Web <-- invalid customer`.
* **Solución:** Uso estratégico del tipo de datos laxo `VARCHAR` en la capa Bronze combinado con funciones de tokenización y parsing de strings como `TRIM()`, `SPLIT_PART()` y `REGEXP_SUBSTR()`.
* **Justificación:** Evita que cargas masivas fallen instantáneamente (*Abort Statement*), aislando el dato atómico puro para su tipificación posterior en la capa Silver.

### 4. Correos Electrónicos Mal Formados
* **Problema:** Direcciones de email inválidas con caracteres especiales redundantes (ej. `sam@@example..com` o `noemail@`).
* **Solución:** Validación y filtrado a través de expresiones regulares complejas mediante la función `REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$')`. Los correos inválidos se fuerzan a `NULL`.

### 5. Encabezados y Pies de Página No Estándar (Banners `-----`)
* **Problema:** Todos los archivos reales contienen banners como `----- START OF FILE... -----` y `----- END OF FILE -----`. Esto rompe los parsers estructurados y ensucia los datos de texto.
* **Solución (CSV):** Uso de `SKIP_HEADER = 2` en el formato del archivo y aplicación de la cláusula `WHERE $1 NOT LIKE '-%'` durante la ejecución de `COPY INTO` para ignorar el banner de pie de página.
* **Solución (JSON/XML):** Carga línea por línea del archivo en bruto a través de un `FILE_FORMAT` de tipo texto plano, exclusión en caliente mediante filtros SQL de las filas que comienzan con `-----` y agregación del string final con `LISTAGG` ordenado por la variable de metadatos `METADATA$FILE_ROW_NUMBER` para realizar el parseo estructurado nativo.

### 6. Comentarios de Javascript en Estructuras JSON
* **Problema:** Presencia de comentarios explicativos de tipo `//` dentro del archivo `transactions.json` que violan el estándar de serialización JSON y provocan fallos catastróficos de parsing.
* **Solución:** Aplicación en caliente de `REGEXP_REPLACE($1, '//.*$', '')` sobre cada línea de texto leída desde el Stage, eliminando los comentarios de manera nativa en SQL antes de invocar la función `PARSE_JSON()`.

