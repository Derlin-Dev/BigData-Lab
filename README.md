# Big Data Lab

Laboratorio dockerizado para aprender y practicar el ecosistema Big Data:
**Hadoop (HDFS + YARN)**, **Apache Spark**, **Hive** y **PySpark**, con
**JupyterLab** como interfaz principal de trabajo. Todo se levanta con un
único `docker-compose.yml`.

## Arquitectura

| Servicio | Rol | Puerto (host) |
|---|---|---|
| `namenode` | HDFS NameNode | `9870` (Web UI), `9000` (RPC) |
| `datanode` | HDFS DataNode | - |
| `resourcemanager` | YARN ResourceManager | `8088` (Web UI) |
| `nodemanager` | YARN NodeManager | - |
| `historyserver` | YARN Job History | `8188` (Web UI) |
| `spark-master` | Cluster Spark (standalone) | `7077` (RPC), `8080` (Web UI) |
| `spark-worker` | Worker de Spark (2 cores / 2G) | `8081` (Web UI) |
| `postgres` | Backend del Hive Metastore | `5432` |
| `hive-metastore` | Hive Metastore (Thrift) | `9083` |
| `hive-server` | HiveServer2 (JDBC/Beeline) | `10000` |
| `jupyter` | JupyterLab con PySpark | `8888` |

Todos los servicios comparten la red `bigdata-network`. Spark usa Hive como
catálogo (`spark.sql.catalogImplementation=hive`) y HDFS como warehouse
(`hdfs://namenode:9000/user/hive/warehouse`), por lo que las tablas creadas
desde Spark SQL o PySpark son visibles también desde Hive/Beeline.

## Requisitos previos

- Docker y Docker Compose (plugin `docker compose`, no el binario legacy `docker-compose`)
- ~6 GB de RAM libres para el stack completo
- Puertos libres en el host: `8080`, `8081`, `8088`, `8188`, `8888`, `9000`, `9083`, `9870`, `10000`, `5432`

## Configuración inicial

1. Copia el archivo `.env` a la raíz del proyecto (junto a `docker-compose.yml`) con al menos estas variables:

   ```env
   COMPOSE_PROJECT_NAME=bigdata-lab

   # Hadoop
   HADOOP_IMAGE_TAG=2.0.0-hadoop3.2.1-java8
   CLUSTER_NAME=bigdata-cluster
   CORE_CONF_FS_DEFAULT=hdfs://namenode:9000
   HDFS_REPLICATION=1

   # Postgres (metadata informativa; las credenciales reales están hardcodeadas
   # en docker-compose.yml y hive/conf/hive-site.xml como hive/hive)
   POSTGRES_USER=hive
   POSTGRES_PASSWORD=hive
   POSTGRES_DB=metastore

   # Spark
   SPARK_MASTER_PORT=7077
   SPARK_MASTER_WEBUI_PORT=8080
   SPARK_WORKER_WEBUI_PORT=8081
   ```

   > ⚠️ Nota: `POSTGRES_USER`, `POSTGRES_PASSWORD`, `SPARK_IMAGE_TAG` y
   > `SPARK_MASTER_HOST` están en el `.env` de referencia pero **no** son
   > leídas por `docker-compose.yml` actualmente (las credenciales de Postgres
   > están hardcodeadas como `hive`/`hive`). Si cambias esos valores no tendrán
   > efecto hasta que se parametrice el compose.

2. Dale permisos de ejecución a los scripts:

   ```bash
   chmod +x scripts/*.sh
   ```

## Uso

### Levantar el laboratorio

```bash
./scripts/start.sh
```

Levanta todos los contenedores, espera a que HDFS esté disponible y
automáticamente ejecuta `init-hdfs.sh` (crea la estructura de carpetas en
HDFS) y `upload-datasets.sh` (sube los datasets de `./datasets/raw`).

Opciones:
```bash
./scripts/start.sh --build     # fuerza rebuild de las imágenes propias (spark, hive, jupyter)
./scripts/start.sh --no-init   # levanta el stack sin tocar HDFS
```

### Ver el estado de los servicios

```bash
./scripts/status.sh          # resumen de contenedores + chequeos de salud
./scripts/status.sh --full   # además: reporte de HDFS, nodos YARN y contenido de /datasets
```

### Inicializar HDFS manualmente

```bash
./scripts/init-hdfs.sh
```

Crea (si no existen) `/datasets`, `/datasets/raw`, `/datasets/processed`,
`/datasets/sample` y `/user/hive/warehouse`, y sube `prueba.txt` (usado por
`spark/apps/ventas.py`). Es idempotente: se puede correr varias veces sin
duplicar datos.

### Subir/actualizar datasets

```bash
./scripts/upload-datasets.sh
```

Sube (sobrescribiendo) todo el contenido de `./datasets/raw` a `/datasets/raw`
en HDFS. Se puede correr independientemente de `init-hdfs.sh` para actualizar
datos sin tocar la estructura de carpetas.

### Detener el laboratorio

```bash
./scripts/stop.sh            # detiene y elimina contenedores, conserva ./data
./scripts/stop.sh --pause    # solo pausa los contenedores (docker compose stop)
./scripts/stop.sh --volumes  # además borra ./data (HDFS, Postgres, notebooks) -- pide confirmación
```

## Acceso a los servicios

| Servicio | URL |
|---|---|
| JupyterLab | http://localhost:8888 |
| HDFS NameNode UI | http://localhost:9870 |
| YARN ResourceManager UI | http://localhost:8088 |
| Spark Master UI | http://localhost:8080 |
| Spark Worker UI | http://localhost:8081 |
| YARN Job History | http://localhost:8188 |

Jupyter no requiere token ni contraseña (configurado para uso local de
laboratorio).

### Conexión a Hive vía Beeline

```bash
docker exec -it hive-server beeline -u "jdbc:hive2://localhost:10000"
```

## Estructura del proyecto

```
BigData-Lab/
├── data/                 # Datos persistentes (HDFS, Postgres, notebooks, eventos Spark) -- ignorado por git
├── datasets/
│   ├── raw/              # Datasets de entrada (ej. BI_Estadistica_Descriptiva.csv)
│   ├── processed/        # Datasets ya transformados
│   └── sample/           # Muestras pequeñas para pruebas rápidas
├── docker-compose.yml
├── docs/                 # Documentación adicional del laboratorio
├── hadoop/conf/          # Configuración extra de Hadoop (si aplica)
├── hive/
│   ├── Dockerfile
│   ├── conf/hive-site.xml
│   ├── lib/              # Driver JDBC de PostgreSQL
│   └── scripts/entrypoint.sh
├── jupyter/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── startup.sh
├── scripts/
│   ├── start.sh
│   ├── init-hdfs.sh
│   ├── upload-datasets.sh
│   ├── status.sh
│   └── stop.sh
└── spark/
    ├── Dockerfile
    ├── apps/ventas.py    # Script de prueba de conectividad Spark-HDFS
    └── conf/
        ├── spark-defaults.conf
        └── log4j2.properties
```

## Notas y limitaciones conocidas

- **Sin Spark History Server en el compose**: el event log está habilitado
  (`spark.eventLog.enabled=true`, `/tmp/spark-events`), pero no hay un
  servicio que sirva esa UI. Los eventos se acumulan en `data/spark/events/`.
- **`spark/apps/ventas.py`** es actualmente un script de prueba de
  conectividad (lee `/datasets/prueba.txt`), no un análisis sobre
  `BI_Estadistica_Descriptiva.csv`.
- Si cambias `CLUSTER_NAME` en `.env` después de haber formateado HDFS, el
  datanode puede rechazar los bloques existentes y moverlos a una carpeta
  `.backup`. Si eso ocurre, revisa `docker logs datanode` antes de asumir
  pérdida de datos.

## Roadmap / pendientes

- [ ] Agregar `.env.example` versionado en git
- [ ] Agregar Spark History Server al compose
- [ ] Adaptar/renombrar `ventas.py` para trabajar sobre el dataset real
- [ ] Documentación adicional en `docs/`