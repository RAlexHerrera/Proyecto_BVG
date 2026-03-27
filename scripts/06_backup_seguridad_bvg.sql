-- Verificar tamaño actual de la BD (útil para monitoreo)
SELECT
    pg_database.datname                         AS base_de_datos,
    pg_size_pretty(pg_database_size(datname))   AS tamaño
FROM pg_database
WHERE datname = 'bvg';

-- Ver últimas conexiones activas
SELECT pid, usename, application_name, client_addr, state, query_start
FROM pg_stat_activity
WHERE datname = 'bvg';

-- Verificar que todos los objetos están creados correctamente
SELECT
    table_name,
    pg_size_pretty(pg_total_relation_size(quote_ident(table_name))) AS tamaño
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;


-- ============================================================
-- PARTE B: COMANDOS BASH PARA BACKUP CON pg_dump
-- Ejecutar desde terminal del servidor o máquina local
-- ============================================================

/*
-----------------------------------------------------------------
VARIABLES DE ENTORNO RECOMENDADAS (agregar a .bashrc o .env)
-----------------------------------------------------------------

export PGHOST=localhost
export PGPORT=5432
export PGUSER=postgres
export PGDATABASE=bvg
export PGPASSWORD=tu_password        -- o usar .pgpass
export BVG_BACKUP_DIR=/backups/bvg

-----------------------------------------------------------------
TIPO 1: BACKUP COMPLETO (schema + datos)
Frecuencia recomendada: DIARIO (en la noche)
-----------------------------------------------------------------

pg_dump \
  --host=$PGHOST \
  --port=$PGPORT \
  --username=$PGUSER \
  --dbname=$PGDATABASE \
  --format=custom \
  --compress=9 \
  --file=$BVG_BACKUP_DIR/bvg_full_$(date +%Y%m%d_%H%M%S).backup \
  --verbose

-----------------------------------------------------------------
TIPO 2: BACKUP SOLO SCHEMA (estructura sin datos)
Frecuencia recomendada: Cada vez que se modifique el schema
-----------------------------------------------------------------

pg_dump \
  --host=$PGHOST \
  --port=$PGPORT \
  --username=$PGUSER \
  --dbname=$PGDATABASE \
  --schema-only \
  --format=plain \
  --file=$BVG_BACKUP_DIR/bvg_schema_$(date +%Y%m%d).sql

-----------------------------------------------------------------
TIPO 3: BACKUP SOLO DATOS (para migración o auditoría)
-----------------------------------------------------------------

pg_dump \
  --host=$PGHOST \
  --port=$PGPORT \
  --username=$PGUSER \
  --dbname=$PGDATABASE \
  --data-only \
  --format=custom \
  --file=$BVG_BACKUP_DIR/bvg_data_$(date +%Y%m%d_%H%M%S).backup

-----------------------------------------------------------------
TIPO 4: BACKUP DE TABLAS CRÍTICAS INDIVIDUALES
(clientes, prestamos, pagos — las más sensibles)
-----------------------------------------------------------------

for TABLA in clientes prestamos pagos amortizacion cuentas; do
  pg_dump \
    --host=$PGHOST \
    --username=$PGUSER \
    --dbname=$PGDATABASE \
    --table=$TABLA \
    --format=custom \
    --file=$BVG_BACKUP_DIR/bvg_${TABLA}_$(date +%Y%m%d).backup
done

-----------------------------------------------------------------
RESTAURAR UN BACKUP
-----------------------------------------------------------------

pg_restore \
  --host=$PGHOST \
  --port=$PGPORT \
  --username=$PGUSER \
  --dbname=bvg_restaurado \     -- ojo: restaurar en BD nueva, no en producción
  --verbose \
  --clean \
  $BVG_BACKUP_DIR/bvg_full_20240101_020000.backup

-----------------------------------------------------------------
VERIFICAR INTEGRIDAD DEL BACKUP (sin restaurar)
-----------------------------------------------------------------

pg_restore --list $BVG_BACKUP_DIR/bvg_full_20240101_020000.backup | head -50

*/


-- ============================================================
-- PARTE C: AUTOMATIZACIÓN CON CRON (Linux/Mac)
-- ============================================================

/*
Editar crontab con: crontab -e

-----------------------------------------------------------------
SCHEDULE RECOMENDADO:
-----------------------------------------------------------------

# Backup completo diario a las 2:00 AM
0 2 * * * /bin/bash /scripts/bvg_backup_full.sh >> /logs/bvg_backup.log 2>&1

# Backup de tablas críticas cada 6 horas
0 */6 * * * /bin/bash /scripts/bvg_backup_critico.sh >> /logs/bvg_backup.log 2>&1

# Limpiar backups con más de 30 días
0 3 * * 0 find /backups/bvg -name "*.backup" -mtime +30 -delete

*/


-- ============================================================
-- PARTE D: SCRIPT BASH COMPLETO (guardar como bvg_backup_full.sh)
-- ============================================================

/*
#!/bin/bash
# ============================================================
# bvg_backup_full.sh
# Backup automático BVG - Banco de Vivienda Guatemala
# ============================================================

set -e

# Configuración
PGHOST="localhost"
PGPORT="5432"
PGUSER="postgres"
PGDATABASE="bvg"
BACKUP_DIR="/backups/bvg"
LOG_FILE="/logs/bvg_backup.log"
RETENTION_DAYS=30
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Crear directorio si no existe
mkdir -p $BACKUP_DIR

echo "[$TIMESTAMP] Iniciando backup BVG..." | tee -a $LOG_FILE

# Backup completo
BACKUP_FILE="$BACKUP_DIR/bvg_full_$TIMESTAMP.backup"

PGPASSWORD=$PGPASSWORD pg_dump \
  --host=$PGHOST \
  --port=$PGPORT \
  --username=$PGUSER \
  --dbname=$PGDATABASE \
  --format=custom \
  --compress=9 \
  --file=$BACKUP_FILE

if [ $? -eq 0 ]; then
    SIZE=$(du -sh $BACKUP_FILE | cut -f1)
    echo "[$TIMESTAMP] ✅ Backup exitoso: $BACKUP_FILE ($SIZE)" | tee -a $LOG_FILE
else
    echo "[$TIMESTAMP] ❌ ERROR en backup" | tee -a $LOG_FILE
    exit 1
fi

# Limpiar backups antiguos
DELETED=$(find $BACKUP_DIR -name "*.backup" -mtime +$RETENTION_DAYS -delete -print | wc -l)
echo "[$TIMESTAMP] 🗑  Backups eliminados (>$RETENTION_DAYS días): $DELETED" | tee -a $LOG_FILE

echo "[$TIMESTAMP] Backup finalizado." | tee -a $LOG_FILE
*/


-- ============================================================
-- PARTE E: POLÍTICA DE RETENCIÓN RECOMENDADA
-- ============================================================

/*
┌─────────────────┬──────────────┬────────────┬─────────────┐
│ Tipo de Backup  │ Frecuencia   │ Retención  │ Almacenaje  │
├─────────────────┼──────────────┼────────────┼─────────────┤
│ Completo        │ Diario 2 AM  │ 30 días    │ Local + S3  │
│ Schema          │ Semanal      │ 90 días    │ Local       │
│ Tablas críticas │ Cada 6 horas │ 7 días     │ Local       │
│ Mensual         │ Día 1 c/mes  │ 1 año      │ S3 Glacier  │
└─────────────────┴──────────────┴────────────┴─────────────┘

Tablas críticas: clientes, cuentas, prestamos, amortizacion, pagos
*/


-- ============================================================
-- PARTE F: SEGURIDAD ADICIONAL EN BD
-- ============================================================

-- Revocar acceso público al schema
REVOKE ALL ON SCHEMA public FROM PUBLIC;

-- Solo el rol app puede conectarse a bvg
REVOKE CONNECT ON DATABASE bvg FROM PUBLIC;
GRANT  CONNECT ON DATABASE bvg TO bvg_app;
GRANT  CONNECT ON DATABASE bvg TO bvg_admin;
GRANT  CONNECT ON DATABASE bvg TO bvg_readonly;

-- Forzar SSL en conexiones (agregar en postgresql.conf)
-- ssl = on
-- ssl_cert_file = 'server.crt'
-- ssl_key_file  = 'server.key'

-- Row Level Security: solo el cliente ve sus propios datos
ALTER TABLE cuentas   ENABLE ROW LEVEL SECURITY;
ALTER TABLE prestamos ENABLE ROW LEVEL SECURITY;
ALTER TABLE pagos     ENABLE ROW LEVEL SECURITY;

-- Política: bvg_app puede ver todo (la app filtra por usuario)
CREATE POLICY policy_cuentas_app
    ON cuentas FOR ALL
    TO bvg_app
    USING (TRUE);

CREATE POLICY policy_prestamos_app
    ON prestamos FOR ALL
    TO bvg_app
    USING (TRUE);

CREATE POLICY policy_pagos_app
    ON pagos FOR ALL
    TO bvg_app
    USING (TRUE);

-- ============================================================
-- FIN ESQUEMA DE BACKUP Y SEGURIDAD
-- ============================================================