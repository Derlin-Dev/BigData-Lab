#!/bin/bash
set -e

if [ "$SERVICE_NAME" = "metastore" ]; then

    echo "Inicializando esquema del metastore..."

    schematool \
        -dbType postgres \
        -initSchema || true

    echo "Iniciando Hive Metastore..."

    exec hive --service metastore

fi

if [ "$SERVICE_NAME" = "hiveserver2" ]; then

    echo "Iniciando HiveServer2..."

    exec hive --service hiveserver2

fi

echo "SERVICE_NAME inválido"

exit 1