#!/bin/bash
#
# start.sh - Levanta el laboratorio Big Data completo
#
# Uso:
#   ./scripts/start.sh            # levanta todo y prepara HDFS
#   ./scripts/start.sh --build    # fuerza rebuild de las imágenes propias
#   ./scripts/start.sh --no-init  # levanta el stack sin correr init-hdfs.sh

set -euo pipefail

# --- Colores para logging ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[start]${NC} $1"; }
warn() { echo -e "${YELLOW}[start]${NC} $1"; }
err()  { echo -e "${RED}[start]${NC} $1" >&2; }

# --- Ir a la raíz del proyecto (un nivel arriba de scripts/) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

# --- Verificar que exista .env ---
if [ ! -f ".env" ]; then
    err "No se encontró el archivo .env en la raíz del proyecto."
    err "Copia .env.example a .env y ajusta los valores antes de continuar."
    exit 1
fi

# --- Verificar que docker compose esté disponible ---
if ! command -v docker &> /dev/null; then
    err "Docker no está instalado o no está en el PATH."
    exit 1
fi

# --- Parsear argumentos ---
BUILD_FLAG=""
RUN_INIT=true

for arg in "$@"; do
    case "$arg" in
        --build)
            BUILD_FLAG="--build"
            ;;
        --no-init)
            RUN_INIT=false
            ;;
        *)
            warn "Argumento desconocido: $arg (ignorado)"
            ;;
    esac
done

# --- Levantar el stack ---
log "Levantando servicios con docker compose..."
docker compose up -d $BUILD_FLAG

# --- Esperar a que el NameNode esté disponible ---
log "Esperando a que HDFS (NameNode) esté disponible..."
MAX_RETRIES=30
RETRY=0

until docker exec namenode hdfs dfsadmin -report &> /dev/null; do
    RETRY=$((RETRY + 1))
    if [ "$RETRY" -ge "$MAX_RETRIES" ]; then
        err "El NameNode no respondió después de $MAX_RETRIES intentos."
        err "Revisa los logs con: docker logs namenode"
        exit 1
    fi
    printf "."
    sleep 5
done
echo ""
log "HDFS está disponible."

# --- Inicializar estructura de HDFS y cargar datasets ---
if [ "$RUN_INIT" = true ]; then
    log "Ejecutando init-hdfs.sh..."
    "$SCRIPT_DIR/init-hdfs.sh"

    log "Ejecutando upload-datasets.sh..."
    "$SCRIPT_DIR/upload-datasets.sh"
else
    warn "Se omitió init-hdfs.sh y upload-datasets.sh (--no-init)."
fi

log "Laboratorio levantado correctamente."
log "Ejecuta ./scripts/status.sh para ver el estado de los servicios."