-- ============================================================
-- 04_seguridad_bvg.sql
-- Banco de Vivienda Guatemala (BVG)
-- Solo partes ejecutables: monitoreo y seguridad
-- ============================================================

-- ============================================================
-- PARTE A: VERIFICACIÓN Y MONITOREO
-- ============================================================

-- Tamaño de la BD
SELECT
    pg_database.datname                         AS base_de_datos,
    pg_size_pretty(pg_database_size(datname))   AS tamaño
FROM pg_database
WHERE datname = 'bvg';

-- Tamaño de cada tabla
SELECT
    table_name,
    pg_size_pretty(pg_total_relation_size(quote_ident(table_name))) AS tamaño
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- ============================================================
-- PARTE F: SEGURIDAD ADICIONAL
-- ============================================================

-- Revocar acceso público al schema
REVOKE ALL ON SCHEMA public FROM PUBLIC;

-- Control de conexiones a la BD bvg
REVOKE CONNECT ON DATABASE bvg FROM PUBLIC;
GRANT  CONNECT ON DATABASE bvg TO bvg_app;
GRANT  CONNECT ON DATABASE bvg TO bvg_admin;
GRANT  CONNECT ON DATABASE bvg TO bvg_readonly;

-- Row Level Security
ALTER TABLE cuentas   ENABLE ROW LEVEL SECURITY;
ALTER TABLE prestamos ENABLE ROW LEVEL SECURITY;
ALTER TABLE pagos     ENABLE ROW LEVEL SECURITY;

-- Políticas de acceso para bvg_app
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
-- FIN
-- ============================================================