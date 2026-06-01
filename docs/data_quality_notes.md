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
