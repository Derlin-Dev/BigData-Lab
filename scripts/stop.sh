#!/bin/bash
#
# stop.sh - Detiene el laboratorio Big Data.
#
# Uso:
#   ./scripts/stop.sh              # detiene y elimina los contenedores (conserva datos en ./data)
#   ./scripts/stop.sh --volumes    # además borra los datos persistentes (./data) -- DESTRUCTIVO
#   ./scripts/stop.sh --pause      # solo pausa los contenedores (docker compose stop), no los elimina

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[stop]${NC} $1"; }
warn() { echo -e "${YELLOW}[stop]${NC} $1"; }
err()  { echo -e "${RED}[stop]${NC} $1" >&2; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

MODE="down"

for arg in "$@"; do
    case "$arg" in
        --volumes)
            MODE="down_volumes"
            ;;
        --pause)
            MODE="stop"
            ;;
        *)
            warn "Argumento desconocido: $arg (ignorado)"
            ;;
    esac
done

case "$MODE" in
    stop)
        log "Pausando contenedores (docker compose stop)..."
        docker compose stop
        log "Contenedores pausados. Usa 'docker compose start' o ./scripts/start.sh para reanudar."
        ;;
    down)
        log "Deteniendo y eliminando contenedores (los datos en ./data se conservan)..."
        docker compose down
        log "Laboratorio detenido."
        ;;
    down_volumes)
        warn "Esto eliminará TODOS los datos persistentes en ./data (HDFS, Postgres, notebooks, eventos de Spark)."
        read -r -p "¿Confirmas que quieres continuar? [y/N] " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            docker compose down
            log "Eliminando ./data ..."
            rm -rf ./data
            log "Contenedores y datos eliminados. El próximo start.sh formateará HDFS desde cero."
        else
            warn "Operación cancelada."
            exit 0
        fi
        ;;
esac