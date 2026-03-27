#!/bin/bash
# ============================================================
# init_bvg.sh
# Script de inicialización automática de la BD BVG en Docker
#
# Docker ejecuta automáticamente los archivos en
# /docker-entrypoint-initdb.d/ al crear el contenedor por
# primera vez, en orden alfabético.
#
# Este script se encarga de ejecutarlos en el orden correcto.
# ============================================================

set -e

echo "================================================"
echo " BVG - Inicializando base de datos..."
echo "================================================"

# La BD 'bvg' ya fue creada por POSTGRES_DB en docker-compose
# Solo necesitamos ejecutar el schema y los datos

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "bvg" <<-EOSQL

    -- Extensiones
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";

    -- Confirmar
    SELECT version();
    SELECT current_database();

EOSQL

echo "✅ Extensiones instaladas"
echo "================================================"
echo " BVG - Base de datos lista."
echo "================================================"