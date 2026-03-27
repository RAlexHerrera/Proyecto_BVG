-- ============================================================
-- PASO 2: SCHEMA COMPLETO - BANCO DE VIVIENDA GUATEMALA
-- Base de datos: BVG
--
-- ⚠️  IMPORTANTE: Ejecutar este script YA conectado a la BD 'bvg'
--     En DBeaver: clic derecho en BVG → Open SQL Script → ejecutar
-- ============================================================

-- ============================================================
-- EXTENSIONES
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- TIPOS ENUMERADOS
-- ============================================================
CREATE TYPE tipo_cuenta_enum AS ENUM (
    'AHORROS',
    'MONETARIA',
    'DOLARES',
    'EMPRESARIAL'
);

CREATE TYPE moneda_enum AS ENUM (
    'GTQ',
    'USD'
);

CREATE TYPE estado_cuenta_enum AS ENUM (
    'ACTIVA',
    'INACTIVA',
    'BLOQUEADA',
    'CERRADA'
);

CREATE TYPE tipo_prestamo_enum AS ENUM (
    'PERSONAL',
    'HIPOTECARIO',
    'VEHICULAR',
    'COMERCIAL'
);

CREATE TYPE estado_prestamo_enum AS ENUM (
    'ACTIVO',
    'PAGADO',
    'VENCIDO',
    'CANCELADO'
);

CREATE TYPE estado_cuota_enum AS ENUM (
    'PENDIENTE',
    'PAGADA',
    'VENCIDA',
    'PAGADA_PARCIAL'
);

CREATE TYPE tipo_solicitud_enum AS ENUM (
    'CREDITO',
    'NUEVA_CUENTA'
);

CREATE TYPE estado_solicitud_enum AS ENUM (
    'PENDIENTE',
    'EN_REVISION',
    'APROBADA',
    'RECHAZADA'
);

CREATE TYPE metodo_pago_enum AS ENUM (
    'EFECTIVO',
    'TRANSFERENCIA',
    'CHEQUE',
    'DEBITO_AUTOMATICO'
);

-- ============================================================
-- TABLA: ROLES
-- ============================================================
CREATE TABLE roles (
    id_rol          SERIAL          PRIMARY KEY,
    nombre          VARCHAR(50)     NOT NULL UNIQUE,
    descripcion     TEXT,
    activo          BOOLEAN         NOT NULL DEFAULT TRUE,
    fecha_creacion  TIMESTAMP       NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE roles IS 'Roles del sistema: CLIENTE, COLABORADOR, ADMIN';

-- ============================================================
-- TABLA: COLABORADORES
-- ============================================================
CREATE TABLE colaboradores (
    id_colaborador  SERIAL          PRIMARY KEY,
    nombres         VARCHAR(100)    NOT NULL,
    apellidos       VARCHAR(100)    NOT NULL,
    dpi             VARCHAR(20)     NOT NULL UNIQUE,
    puesto          VARCHAR(100)    NOT NULL,
    email           VARCHAR(150)    NOT NULL UNIQUE,
    telefono        VARCHAR(20),
    activo          BOOLEAN         NOT NULL DEFAULT TRUE,
    fecha_ingreso   DATE            NOT NULL DEFAULT CURRENT_DATE,
    fecha_creacion  TIMESTAMP       NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE colaboradores IS 'Empleados del banco con acceso al sistema';

-- ============================================================
-- TABLA: CLIENTES
-- ============================================================
CREATE TABLE clientes (
    id_cliente      SERIAL          PRIMARY KEY,
    nombres         VARCHAR(100)    NOT NULL,
    apellidos       VARCHAR(100)    NOT NULL,
    dpi             VARCHAR(20)     NOT NULL UNIQUE,
    nit             VARCHAR(20)     UNIQUE,
    telefono        VARCHAR(20),
    email           VARCHAR(150)    UNIQUE,
    direccion       TEXT,
    fecha_nacimiento DATE,
    activo          BOOLEAN         NOT NULL DEFAULT TRUE,
    fecha_registro  TIMESTAMP       NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE clientes IS 'Clientes del banco con sus datos personales';

-- ============================================================
-- TABLA: USUARIOS
-- ============================================================
CREATE TABLE usuarios (
    id_usuario          SERIAL          PRIMARY KEY,
    id_rol              INT             NOT NULL REFERENCES roles(id_rol),
    id_cliente          INT             REFERENCES clientes(id_cliente),
    id_colaborador      INT             REFERENCES colaboradores(id_colaborador),
    username            VARCHAR(80)     NOT NULL UNIQUE,
    password_hash       TEXT            NOT NULL,
    activo              BOOLEAN         NOT NULL DEFAULT TRUE,
    intentos_fallidos   INT             NOT NULL DEFAULT 0,
    ultimo_acceso       TIMESTAMP,
    fecha_creacion      TIMESTAMP       NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_usuario_tipo CHECK (
        (id_cliente IS NOT NULL AND id_colaborador IS NULL) OR
        (id_cliente IS NULL AND id_colaborador IS NOT NULL)
    )
);

COMMENT ON TABLE usuarios IS 'Credenciales de acceso al sistema BVG';
COMMENT ON COLUMN usuarios.password_hash IS 'Hash bcrypt via pgcrypto: crypt(password, gen_salt(bcrypt))';

-- ============================================================
-- TABLA: CUENTAS
-- ============================================================
CREATE TABLE cuentas (
    id_cuenta           SERIAL                  PRIMARY KEY,
    id_cliente          INT                     NOT NULL REFERENCES clientes(id_cliente),
    numero_cuenta       VARCHAR(20)             NOT NULL UNIQUE,
    tipo_cuenta         tipo_cuenta_enum        NOT NULL,
    moneda              moneda_enum             NOT NULL DEFAULT 'GTQ',
    saldo               NUMERIC(15,2)           NOT NULL DEFAULT 0.00,
    estado              estado_cuenta_enum      NOT NULL DEFAULT 'ACTIVA',
    fecha_apertura      DATE                    NOT NULL DEFAULT CURRENT_DATE,
    fecha_actualizacion TIMESTAMP               NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_saldo_no_negativo CHECK (saldo >= 0)
);

COMMENT ON TABLE cuentas IS 'Cuentas bancarias: AHORROS, MONETARIA, DOLARES, EMPRESARIAL';

-- ============================================================
-- TABLA: PRÉSTAMOS
-- ============================================================
CREATE TABLE prestamos (
    id_prestamo         SERIAL                  PRIMARY KEY,
    id_cliente          INT                     NOT NULL REFERENCES clientes(id_cliente),
    id_colaborador      INT                     NOT NULL REFERENCES colaboradores(id_colaborador),
    numero_prestamo     VARCHAR(20)             NOT NULL UNIQUE,
    tipo_prestamo       tipo_prestamo_enum      NOT NULL,
    monto_original      NUMERIC(15,2)           NOT NULL,
    saldo_pendiente     NUMERIC(15,2)           NOT NULL,
    tasa_interes        NUMERIC(5,2)            NOT NULL,
    plazo_meses         INT                     NOT NULL,
    cuota_mensual       NUMERIC(15,2)           NOT NULL,
    estado              estado_prestamo_enum    NOT NULL DEFAULT 'ACTIVO',
    fecha_aprobacion    DATE                    NOT NULL DEFAULT CURRENT_DATE,
    fecha_primer_pago   DATE                    NOT NULL,
    fecha_vencimiento   DATE                    NOT NULL,
    observaciones       TEXT,
    fecha_creacion      TIMESTAMP               NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_monto_positivo   CHECK (monto_original > 0),
    CONSTRAINT chk_saldo_positivo   CHECK (saldo_pendiente >= 0),
    CONSTRAINT chk_tasa_positiva    CHECK (tasa_interes > 0),
    CONSTRAINT chk_plazo_positivo   CHECK (plazo_meses > 0)
);

COMMENT ON TABLE prestamos IS 'Préstamos otorgados con condiciones y estado actual';

-- ============================================================
-- TABLA: AMORTIZACIÓN
-- ============================================================
CREATE TABLE amortizacion (
    id_cuota            SERIAL                  PRIMARY KEY,
    id_prestamo         INT                     NOT NULL REFERENCES prestamos(id_prestamo),
    numero_cuota        INT                     NOT NULL,
    fecha_vencimiento   DATE                    NOT NULL,
    monto_cuota         NUMERIC(15,2)           NOT NULL,
    capital             NUMERIC(15,2)           NOT NULL,
    interes             NUMERIC(15,2)           NOT NULL,
    saldo_restante      NUMERIC(15,2)           NOT NULL,
    estado              estado_cuota_enum       NOT NULL DEFAULT 'PENDIENTE',
    fecha_pago_real     DATE,

    CONSTRAINT chk_numero_cuota_positivo    CHECK (numero_cuota > 0),
    CONSTRAINT uq_prestamo_cuota            UNIQUE (id_prestamo, numero_cuota)
);

COMMENT ON TABLE amortizacion IS 'Cuotas programadas de cada préstamo (tabla de amortización)';

-- ============================================================
-- TABLA: PAGOS
-- ============================================================
CREATE TABLE pagos (
    id_pago             SERIAL                  PRIMARY KEY,
    id_cuota            INT                     NOT NULL REFERENCES amortizacion(id_cuota),
    id_prestamo         INT                     NOT NULL REFERENCES prestamos(id_prestamo),
    id_colaborador      INT                     REFERENCES colaboradores(id_colaborador),
    fecha_pago          TIMESTAMP               NOT NULL DEFAULT NOW(),
    monto_pagado        NUMERIC(15,2)           NOT NULL,
    metodo_pago         metodo_pago_enum        NOT NULL DEFAULT 'EFECTIVO',
    numero_referencia   VARCHAR(100),
    observaciones       TEXT,
    fecha_creacion      TIMESTAMP               NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_monto_pagado_positivo CHECK (monto_pagado > 0)
);

COMMENT ON TABLE pagos IS 'Registro histórico de todos los pagos realizados';

-- ============================================================
-- TABLA: SOLICITUDES
-- ============================================================
CREATE TABLE solicitudes (
    id_solicitud            SERIAL                      PRIMARY KEY,
    id_cliente              INT                         NOT NULL REFERENCES clientes(id_cliente),
    id_colaborador          INT                         REFERENCES colaboradores(id_colaborador),
    tipo                    tipo_solicitud_enum         NOT NULL,
    estado                  estado_solicitud_enum       NOT NULL DEFAULT 'PENDIENTE',
    monto_solicitado        NUMERIC(15,2),
    plazo_solicitado        INT,
    tipo_cuenta_solicitada  tipo_cuenta_enum,
    descripcion             TEXT,
    motivo_rechazo          TEXT,
    fecha_solicitud         TIMESTAMP                   NOT NULL DEFAULT NOW(),
    fecha_resolucion        TIMESTAMP
);

COMMENT ON TABLE solicitudes IS 'Solicitudes de crédito o apertura de cuenta';

-- ============================================================
-- TABLA: AUDITORÍA
-- ============================================================
CREATE TABLE auditoria (
    id_auditoria    SERIAL          PRIMARY KEY,
    id_usuario      INT             REFERENCES usuarios(id_usuario),
    accion          VARCHAR(100)    NOT NULL,
    tabla_afectada  VARCHAR(100),
    registro_id     INT,
    detalle         TEXT,
    ip_origen       VARCHAR(45),
    fecha           TIMESTAMP       NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE auditoria IS 'Log de auditoría y trazabilidad del sistema';

-- ============================================================
-- ÍNDICES
-- ============================================================
CREATE INDEX idx_clientes_dpi               ON clientes(dpi);
CREATE INDEX idx_clientes_email             ON clientes(email);
CREATE INDEX idx_cuentas_cliente            ON cuentas(id_cliente);
CREATE INDEX idx_cuentas_numero             ON cuentas(numero_cuenta);
CREATE INDEX idx_cuentas_tipo               ON cuentas(tipo_cuenta);
CREATE INDEX idx_prestamos_cliente          ON prestamos(id_cliente);
CREATE INDEX idx_prestamos_estado           ON prestamos(estado);
CREATE INDEX idx_prestamos_numero           ON prestamos(numero_prestamo);
CREATE INDEX idx_amortizacion_prestamo      ON amortizacion(id_prestamo);
CREATE INDEX idx_amortizacion_vencimiento   ON amortizacion(fecha_vencimiento);
CREATE INDEX idx_amortizacion_estado        ON amortizacion(estado);
CREATE INDEX idx_pagos_prestamo             ON pagos(id_prestamo);
CREATE INDEX idx_pagos_cuota                ON pagos(id_cuota);
CREATE INDEX idx_pagos_fecha                ON pagos(fecha_pago);
CREATE INDEX idx_solicitudes_cliente        ON solicitudes(id_cliente);
CREATE INDEX idx_solicitudes_estado         ON solicitudes(estado);
CREATE INDEX idx_usuarios_username          ON usuarios(username);
CREATE INDEX idx_auditoria_usuario          ON auditoria(id_usuario);
CREATE INDEX idx_auditoria_fecha            ON auditoria(fecha);

-- ============================================================
-- SEGURIDAD: ROLES DE BASE DE DATOS
-- ============================================================
DO $$ BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'bvg_readonly') THEN
        CREATE ROLE bvg_readonly;
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'bvg_app') THEN
        CREATE ROLE bvg_app;
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'bvg_admin') THEN
        CREATE ROLE bvg_admin;
    END IF;
END $$;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO bvg_readonly;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO bvg_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO bvg_app;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO bvg_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO bvg_admin;

-- ============================================================
-- DATOS INICIALES
-- ============================================================
INSERT INTO roles (nombre, descripcion) VALUES
    ('ADMIN',       'Administrador del sistema con acceso total'),
    ('COLABORADOR', 'Empleado del banco que gestiona clientes y operaciones'),
    ('CLIENTE',     'Cliente del banco con acceso a sus propias cuentas');

-- ============================================================
-- TRIGGERS Y FUNCIONES
-- ============================================================

-- Auto-generar número de cuenta
CREATE OR REPLACE FUNCTION generar_numero_cuenta()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.numero_cuenta IS NULL OR NEW.numero_cuenta = '' THEN
        NEW.numero_cuenta := 'CTA-' || LPAD(NEW.id_cuenta::TEXT, 10, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_numero_cuenta
    BEFORE INSERT ON cuentas
    FOR EACH ROW EXECUTE FUNCTION generar_numero_cuenta();

-- Auto-generar número de préstamo
CREATE OR REPLACE FUNCTION generar_numero_prestamo()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.numero_prestamo IS NULL OR NEW.numero_prestamo = '' THEN
        NEW.numero_prestamo := 'PRE-' || LPAD(NEW.id_prestamo::TEXT, 10, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_numero_prestamo
    BEFORE INSERT ON prestamos
    FOR EACH ROW EXECUTE FUNCTION generar_numero_prestamo();

-- Actualizar saldo al registrar un pago
CREATE OR REPLACE FUNCTION actualizar_saldo_prestamo()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE prestamos
    SET saldo_pendiente = saldo_pendiente - NEW.monto_pagado
    WHERE id_prestamo = NEW.id_prestamo;

    UPDATE amortizacion
    SET estado = 'PAGADA',
        fecha_pago_real = CURRENT_DATE
    WHERE id_cuota = NEW.id_cuota;

    UPDATE prestamos
    SET estado = 'PAGADO'
    WHERE id_prestamo = NEW.id_prestamo
      AND saldo_pendiente <= 0;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_actualizar_saldo
    AFTER INSERT ON pagos
    FOR EACH ROW EXECUTE FUNCTION actualizar_saldo_prestamo();

-- Marcar cuotas vencidas (ejecutar con pg_cron diariamente)
CREATE OR REPLACE FUNCTION marcar_cuotas_vencidas()
RETURNS void AS $$
BEGIN
    UPDATE amortizacion
    SET estado = 'VENCIDA'
    WHERE estado = 'PENDIENTE'
      AND fecha_vencimiento < CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- VISTAS
-- ============================================================

-- Cuentas por cliente
CREATE VIEW v_cuentas_cliente AS
SELECT
    c.id_cliente,
    c.nombres || ' ' || c.apellidos  AS cliente,
    c.dpi,
    cu.numero_cuenta,
    cu.tipo_cuenta,
    cu.moneda,
    cu.saldo,
    cu.estado,
    cu.fecha_apertura
FROM clientes c
JOIN cuentas cu ON c.id_cliente = cu.id_cliente;

-- Cuotas próximas a vencer (30 días)
CREATE VIEW v_cuotas_por_vencer AS
SELECT
    p.numero_prestamo,
    c.nombres || ' ' || c.apellidos  AS cliente,
    c.telefono,
    c.email,
    a.numero_cuota,
    a.fecha_vencimiento,
    a.monto_cuota,
    a.saldo_restante,
    a.estado,
    (a.fecha_vencimiento - CURRENT_DATE) AS dias_para_vencer
FROM amortizacion a
JOIN prestamos p ON a.id_prestamo = p.id_prestamo
JOIN clientes c  ON p.id_cliente  = c.id_cliente
WHERE a.estado = 'PENDIENTE'
  AND a.fecha_vencimiento BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
ORDER BY a.fecha_vencimiento ASC;

-- Estado de préstamos por cliente
CREATE VIEW v_prestamos_cliente AS
SELECT
    c.id_cliente,
    c.nombres || ' ' || c.apellidos          AS cliente,
    p.numero_prestamo,
    p.tipo_prestamo,
    p.monto_original,
    p.saldo_pendiente,
    p.tasa_interes,
    p.cuota_mensual,
    p.plazo_meses,
    p.estado,
    p.fecha_aprobacion,
    p.fecha_vencimiento,
    col.nombres || ' ' || col.apellidos      AS colaborador_asignado
FROM prestamos p
JOIN clientes c          ON p.id_cliente     = c.id_cliente
JOIN colaboradores col   ON p.id_colaborador = col.id_colaborador;

-- Historial de pagos
CREATE VIEW v_historial_pagos AS
SELECT
    p.numero_prestamo,
    cl.nombres || ' ' || cl.apellidos        AS cliente,
    a.numero_cuota,
    a.fecha_vencimiento,
    pg.fecha_pago,
    pg.monto_pagado,
    pg.metodo_pago,
    pg.numero_referencia,
    col.nombres || ' ' || col.apellidos      AS registrado_por
FROM pagos pg
JOIN amortizacion a         ON pg.id_cuota      = a.id_cuota
JOIN prestamos p            ON pg.id_prestamo   = p.id_prestamo
JOIN clientes cl            ON p.id_cliente     = cl.id_cliente
LEFT JOIN colaboradores col ON pg.id_colaborador = col.id_colaborador
ORDER BY pg.fecha_pago DESC;

-- ============================================================
-- FIN DEL SCRIPT BVG
-- ============================================================