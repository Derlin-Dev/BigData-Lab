#!/bin/bash
#
# status.sh - Muestra el estado de los servicios del laboratorio Big Data.
#
# Uso:
#   ./scripts/status.sh          # resumen de contenedores + chequeos de salud
#   ./scripts/status.sh --full   # además muestra el reporte de HDFS y nodos YARN

set -uo pipefail  # sin -e: queremos seguir aunque un chequeo individual falle

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

ok()    { echo -e "  ${GREEN}✔${NC} $1"; }
fail()  { echo -e "  ${RED}✘${NC} $1"; }
title() { echo -e "\n${BLUE}== $1 ==${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

FULL=false
for arg in "$@"; do
    [ "$arg" = "--full" ] && FULL=true
done

# --- Estado general de docker compose ---
title "Contenedores (docker compose ps)"
docker compose ps

# --- Chequeos de salud por servicio ---
title "Chequeos de salud"

check_container_running() {
    local name="$1"
    if [ "$(docker inspect -f '{{.State.Running}}' "$name" 2>/dev/null)" = "true" ]; then
        return 0
    fi
    return 1
}

# HDFS
if check_container_running namenode && docker exec namenode hdfs dfsadmin -report &> /dev/null; then
    ok "HDFS (namenode) - operativo"
else
    fail "HDFS (namenode) - no responde"
fi

# YARN ResourceManager
if check_container_running resourcemanager && curl -sf http://localhost:8088/ws/v1/cluster/info &> /dev/null; then
    ok "YARN (resourcemanager) - operativo (UI: http://localhost:8088)"
else
    fail "YARN (resourcemanager) - no responde"
fi

# Spark Master
if check_container_running spark-master && curl -sf http://localhost:8080/json/ &> /dev/null; then
    ok "Spark Master - operativo (UI: http://localhost:8080)"
else
    fail "Spark Master - no responde"
fi

# Spark Worker
if check_container_running spark-worker; then
    ok "Spark Worker - contenedor activo"
else
    fail "Spark Worker - no está corriendo"
fi

# Postgres
if check_container_running postgres && docker exec postgres pg_isready -U hive &> /dev/null; then
    ok "PostgreSQL - operativo"
else
    fail "PostgreSQL - no responde"
fi

# Hive Metastore
if check_container_running hive-metastore; then
    ok "Hive Metastore - contenedor activo (puerto 9083)"
else
    fail "Hive Metastore - no está corriendo"
fi

# HiveServer2
if check_container_running hive-server; then
    ok "HiveServer2 - contenedor activo (puerto 10000)"
else
    fail "HiveServer2 - no está corriendo"
fi

# Jupyter
if check_container_running jupyter && curl -sf http://localhost:8888 &> /dev/null; then
    ok "JupyterLab - operativo (http://localhost:8888)"
else
    fail "JupyterLab - no responde"
fi

# --- Detalle extendido opcional ---
if [ "$FULL" = true ]; then
    title "Reporte HDFS"
    docker exec namenode hdfs dfsadmin -report 2>/dev/null || fail "No se pudo obtener el reporte de HDFS"

    title "Nodos YARN"
    docker exec resourcemanager yarn node -list 2>/dev/null || fail "No se pudo obtener la lista de nodos YARN"

    title "Contenido de /datasets en HDFS"
    docker exec namenode hdfs dfs -ls -R /datasets 2>/dev/null || fail "No se pudo listar /datasets"
fi

echo ""