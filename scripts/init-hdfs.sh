#!/bin/bash
#
# init-hdfs.sh - Prepara la estructura de directorios en HDFS
# (/datasets, /datasets/raw, /datasets/processed, /datasets/sample,
# /user/hive/warehouse) y sube prueba.txt (usado por spark/apps/ventas.py).
#
# La carga de los datasets reales en ./datasets/raw se hace aparte con
# ./scripts/upload-datasets.sh (se puede correr independientemente para
# actualizar datos sin tocar la estructura de HDFS).
#
# Se asume que el contenedor "namenode" ya está corriendo y accesible.
# Este script es idempotente: se puede volver a ejecutar sin duplicar datos.

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[init-hdfs]${NC} $1"; }
warn() { echo -e "${YELLOW}[init-hdfs]${NC} $1"; }
err()  { echo -e "${RED}[init-hdfs]${NC} $1" >&2; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

HDFS_EXEC="docker exec namenode hdfs"

# --- Esperar a que el NameNode responda (por si se llama este script solo) ---
log "Verificando disponibilidad del NameNode..."
MAX_RETRIES=30
RETRY=0
until $HDFS_EXEC dfsadmin -report &> /dev/null; do
    RETRY=$((RETRY + 1))
    if [ "$RETRY" -ge "$MAX_RETRIES" ]; then
        err "El NameNode no está disponible. ¿Está corriendo el contenedor 'namenode'?"
        exit 1
    fi
    printf "."
    sleep 5
done
echo ""
log "NameNode disponible."

# --- Crear estructura base de directorios en HDFS ---
log "Creando estructura de directorios en HDFS..."

HDFS_DIRS=(
    "/datasets"
    "/datasets/raw"
    "/datasets/processed"
    "/datasets/sample"
    "/user/hive/warehouse"
)

for dir in "${HDFS_DIRS[@]}"; do
    if $HDFS_EXEC dfs -test -d "$dir" 2>/dev/null; then
        warn "Ya existe: $dir"
    else
        $HDFS_EXEC dfs -mkdir -p "$dir"
        log "Creado: $dir"
    fi
done

# --- Ajustar permisos del warehouse para Hive ---
$HDFS_EXEC dfs -chmod -R 777 /user/hive/warehouse
log "Permisos ajustados en /user/hive/warehouse"

# --- Subir archivo de prueba (usado por spark/apps/ventas.py) ---
if [ -f "prueba.txt" ]; then
    if $HDFS_EXEC dfs -test -f "/datasets/prueba.txt" 2>/dev/null; then
        warn "prueba.txt ya existe en HDFS, se omite."
    else
        docker cp prueba.txt namenode:/tmp/prueba.txt
        $HDFS_EXEC dfs -put /tmp/prueba.txt /datasets/prueba.txt
        docker exec namenode rm -f /tmp/prueba.txt
        log "Subido: prueba.txt -> /datasets/prueba.txt"
    fi
else
    warn "No se encontró prueba.txt en la raíz del proyecto, se omite."
fi

log "Estructura de HDFS inicializada."
log "Para subir los datasets de ./datasets/raw, ejecuta: ./scripts/upload-datasets.sh"
log "Verifica con: docker exec namenode hdfs dfs -ls -R /datasets"