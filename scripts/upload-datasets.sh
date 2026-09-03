#!/bin/bash

set -e

# Obtener la raíz del proyecto automáticamente
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Directorio local de datasets
DATASETS_DIR="$PROJECT_ROOT/datasets/raw"

# Directorio destino en HDFS
HDFS_DIR="/datasets/raw"

echo "========================================="
echo "     CARGA DE DATASETS A HDFS"
echo "========================================="

echo ""
echo "Proyecto:"
echo "$PROJECT_ROOT"

echo ""
echo "Directorio local:"
echo "$DATASETS_DIR"

echo ""
echo "Directorio HDFS:"
echo "$HDFS_DIR"

# Verificar que el directorio local exista
if [ ! -d "$DATASETS_DIR" ]; then
    echo ""
    echo "ERROR: No existe el directorio:"
    echo "$DATASETS_DIR"
    exit 1
fi

# Verificar que NameNode esté ejecutándose
if ! docker ps --format '{{.Names}}' | grep -q '^namenode$'; then
    echo ""
    echo "ERROR: El contenedor namenode no está ejecutándose."
    echo "Ejecuta:"
    echo "docker compose up -d namenode"
    exit 1
fi

echo ""
echo "Creando directorio HDFS..."

docker exec namenode \
    hdfs dfs -mkdir -p "$HDFS_DIR"

echo ""
echo "Buscando datasets..."

found=0

for file in "$DATASETS_DIR"/*; do

    if [ -f "$file" ]; then

        found=1

        filename=$(basename "$file")

        echo ""
        echo "-----------------------------------------"
        echo "Dataset encontrado: $filename"
        echo "-----------------------------------------"

        echo "Copiando al contenedor..."

        docker cp "$file" \
            "namenode:/tmp/$filename"

        echo "Subiendo a HDFS..."

        docker exec namenode \
            hdfs dfs -put -f \
            "/tmp/$filename" \
            "$HDFS_DIR/"

        echo "Eliminando archivo temporal..."

        docker exec namenode \
            rm -f "/tmp/$filename"

        echo "OK: $filename"

    fi

done

if [ "$found" -eq 0 ]; then
    echo ""
    echo "ADVERTENCIA: No se encontraron datasets en:"
    echo "$DATASETS_DIR"
fi

echo ""
echo "========================================="
echo "      CONTENIDO ACTUAL DE HDFS"
echo "========================================="

docker exec namenode \
    hdfs dfs -ls "$HDFS_DIR"

echo ""
echo "========================================="
echo "       CARGA FINALIZADA"
echo "========================================="