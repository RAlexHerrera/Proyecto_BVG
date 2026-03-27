-- ============================================================
-- DÍA 5: STORED PROCEDURES Y FUNCIONES - BVG
-- Banco de Vivienda Guatemala
--
-- ⚠️  Ejecutar conectado a la BD 'bvg'
-- ⚠️  Ejecutar DESPUÉS de los scripts 01 al 03
-- ============================================================


-- ============================================================
-- FUNCIÓN 1: Calcular cuota mensual (fórmula de amortización)
-- Uso: SELECT bvg_calcular_cuota(25000, 18.00, 12);
-- ============================================================
CREATE OR REPLACE FUNCTION bvg_calcular_cuota(
    p_monto      NUMERIC,
    p_tasa_anual NUMERIC,
    p_plazo_meses INT
)
RETURNS NUMERIC AS $$
DECLARE
    v_tasa_mensual NUMERIC;
    v_cuota        NUMERIC;
BEGIN
    -- Tasa mensual
    v_tasa_mensual := p_tasa_anual / 100.0 / 12.0;

    -- Fórmula: M = P * [i(1+i)^n] / [(1+i)^n - 1]
    v_cuota := p_monto
               * (v_tasa_mensual * POWER(1 + v_tasa_mensual, p_plazo_meses))
               / (POWER(1 + v_tasa_mensual, p_plazo_meses) - 1);

    RETURN ROUND(v_cuota, 2);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION bvg_calcular_cuota IS
    'Calcula la cuota mensual fija dado monto, tasa anual y plazo en meses';


-- ============================================================
-- FUNCIÓN 2: Generar tabla de amortización automática
-- Uso: SELECT * FROM bvg_generar_amortizacion(1);
-- Genera y persiste las cuotas en la tabla amortizacion
-- ============================================================
CREATE OR REPLACE FUNCTION bvg_generar_amortizacion(p_id_prestamo INT)
RETURNS TABLE (
    numero_cuota     INT,
    fecha_vencimiento DATE,
    cuota            NUMERIC,
    capital          NUMERIC,
    interes          NUMERIC,
    saldo_restante   NUMERIC
) AS $$
DECLARE
    v_prestamo      RECORD;
    v_tasa_mensual  NUMERIC;
    v_saldo         NUMERIC;
    v_interes       NUMERIC;
    v_capital       NUMERIC;
    v_cuota         NUMERIC;
    v_fecha         DATE;
    i               INT;
BEGIN
    -- Obtener datos del préstamo
    SELECT * INTO v_prestamo
    FROM prestamos
    WHERE id_prestamo = p_id_prestamo;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Préstamo % no encontrado', p_id_prestamo;
    END IF;

    -- Limpiar amortización previa si existe
    DELETE FROM amortizacion WHERE id_prestamo = p_id_prestamo;

    v_tasa_mensual := v_prestamo.tasa_interes / 100.0 / 12.0;
    v_saldo        := v_prestamo.monto_original;
    v_cuota        := v_prestamo.cuota_mensual;
    v_fecha        := v_prestamo.fecha_primer_pago;

    FOR i IN 1..v_prestamo.plazo_meses LOOP
        v_interes := ROUND(v_saldo * v_tasa_mensual, 2);
        v_capital := ROUND(v_cuota - v_interes, 2);

        -- Última cuota: ajustar por redondeos acumulados
        IF i = v_prestamo.plazo_meses THEN
            v_capital := v_saldo;
            v_cuota   := v_capital + v_interes;
        END IF;

        v_saldo := ROUND(v_saldo - v_capital, 2);

        -- Insertar en tabla
        INSERT INTO amortizacion (
            id_prestamo, numero_cuota, fecha_vencimiento,
            monto_cuota, capital, interes, saldo_restante, estado
        ) VALUES (
            p_id_prestamo, i, v_fecha,
            v_cuota, v_capital, v_interes,
            CASE WHEN v_saldo < 0 THEN 0 ELSE v_saldo END,
            'PENDIENTE'
        );

        -- Retornar fila al llamador
        numero_cuota      := i;
        fecha_vencimiento := v_fecha;
        cuota             := v_cuota;
        capital           := v_capital;
        interes           := v_interes;
        saldo_restante    := CASE WHEN v_saldo < 0 THEN 0 ELSE v_saldo END;
        RETURN NEXT;

        v_fecha := v_fecha + INTERVAL '1 month';
    END LOOP;

    RETURN;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION bvg_generar_amortizacion IS
    'Genera y persiste la tabla de amortización completa de un préstamo';


-- ============================================================
-- PROCEDURE 1: Crear cliente completo con usuario
-- Uso: CALL bvg_crear_cliente(...)
-- ============================================================
CREATE OR REPLACE PROCEDURE bvg_crear_cliente(
    p_nombres          VARCHAR,
    p_apellidos        VARCHAR,
    p_dpi              VARCHAR,
    p_nit              VARCHAR,
    p_telefono         VARCHAR,
    p_email            VARCHAR,
    p_direccion        TEXT,
    p_fecha_nacimiento DATE,
    p_username         VARCHAR,
    p_password         VARCHAR,
    OUT p_id_cliente   INT,
    OUT p_id_usuario   INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_id_rol INT;
BEGIN
    -- Obtener id del rol CLIENTE
    SELECT id_rol INTO v_id_rol FROM roles WHERE nombre = 'CLIENTE';

    -- Insertar cliente
    INSERT INTO clientes (nombres, apellidos, dpi, nit, telefono, email, direccion, fecha_nacimiento)
    VALUES (p_nombres, p_apellidos, p_dpi, p_nit, p_telefono, p_email, p_direccion, p_fecha_nacimiento)
    RETURNING id_cliente INTO p_id_cliente;

    -- Crear usuario vinculado
    INSERT INTO usuarios (id_rol, id_cliente, username, password_hash)
    VALUES (v_id_rol, p_id_cliente, p_username, crypt(p_password, gen_salt('bf')))
    RETURNING id_usuario INTO p_id_usuario;

    RAISE NOTICE 'Cliente creado: id=%, usuario: id=%', p_id_cliente, p_id_usuario;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Ya existe un cliente o usuario con esos datos (DPI, NIT, email o username duplicado)';
END;
$$;

COMMENT ON PROCEDURE bvg_crear_cliente IS
    'Crea un cliente y su usuario del sistema en una sola operación atómica';


-- ============================================================
-- PROCEDURE 2: Aprobar solicitud y crear préstamo
-- Uso: CALL bvg_aprobar_prestamo(id_solicitud, id_colaborador, tasa)
-- ============================================================
CREATE OR REPLACE PROCEDURE bvg_aprobar_prestamo(
    p_id_solicitud   INT,
    p_id_colaborador INT,
    p_tasa_interes   NUMERIC,
    OUT p_id_prestamo INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_solicitud RECORD;
    v_cuota     NUMERIC;
BEGIN
    -- Obtener solicitud
    SELECT * INTO v_solicitud
    FROM solicitudes
    WHERE id_solicitud = p_id_solicitud
      AND tipo  = 'CREDITO'
      AND estado IN ('PENDIENTE', 'EN_REVISION');

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Solicitud % no encontrada o no está en estado válido para aprobar', p_id_solicitud;
    END IF;

    -- Calcular cuota mensual
    v_cuota := bvg_calcular_cuota(
        v_solicitud.monto_solicitado,
        p_tasa_interes,
        v_solicitud.plazo_solicitado
    );

    -- Crear préstamo
    INSERT INTO prestamos (
        id_cliente, id_colaborador, numero_prestamo, tipo_prestamo,
        monto_original, saldo_pendiente, tasa_interes, plazo_meses,
        cuota_mensual, estado, fecha_aprobacion,
        fecha_primer_pago, fecha_vencimiento
    ) VALUES (
        v_solicitud.id_cliente,
        p_id_colaborador,
        '',                             -- trigger genera el número
        'PERSONAL',
        v_solicitud.monto_solicitado,
        v_solicitud.monto_solicitado,
        p_tasa_interes,
        v_solicitud.plazo_solicitado,
        v_cuota,
        'ACTIVO',
        CURRENT_DATE,
        CURRENT_DATE + INTERVAL '1 month',
        CURRENT_DATE + (v_solicitud.plazo_solicitado || ' months')::INTERVAL
    ) RETURNING id_prestamo INTO p_id_prestamo;

    -- Generar tabla de amortización automáticamente
    PERFORM bvg_generar_amortizacion(p_id_prestamo);

    -- Actualizar solicitud como aprobada
    UPDATE solicitudes
    SET estado           = 'APROBADA',
        id_colaborador   = p_id_colaborador,
        fecha_resolucion = NOW()
    WHERE id_solicitud = p_id_solicitud;

    RAISE NOTICE 'Préstamo % creado con % cuotas de Q%',
        p_id_prestamo, v_solicitud.plazo_solicitado, v_cuota;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al aprobar préstamo: %', SQLERRM;
END;
$$;

COMMENT ON PROCEDURE bvg_aprobar_prestamo IS
    'Aprueba una solicitud de crédito, crea el préstamo y genera su amortización';


-- ============================================================
-- PROCEDURE 3: Registrar pago de cuota
-- Uso: CALL bvg_registrar_pago(id_prestamo, numero_cuota, monto, metodo, referencia, id_colaborador)
-- ============================================================
CREATE OR REPLACE PROCEDURE bvg_registrar_pago(
    p_id_prestamo      INT,
    p_numero_cuota     INT,
    p_monto_pagado     NUMERIC,
    p_metodo_pago      metodo_pago_enum,
    p_referencia       VARCHAR,
    p_id_colaborador   INT,
    OUT p_id_pago      INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_id_cuota  INT;
    v_estado    estado_cuota_enum;
BEGIN
    -- Buscar cuota
    SELECT id_cuota, estado
    INTO v_id_cuota, v_estado
    FROM amortizacion
    WHERE id_prestamo  = p_id_prestamo
      AND numero_cuota = p_numero_cuota;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cuota % del préstamo % no encontrada', p_numero_cuota, p_id_prestamo;
    END IF;

    IF v_estado = 'PAGADA' THEN
        RAISE EXCEPTION 'La cuota % ya fue pagada', p_numero_cuota;
    END IF;

    -- Insertar pago (trigger actualiza saldo y estado de cuota)
    INSERT INTO pagos (id_cuota, id_prestamo, id_colaborador, monto_pagado, metodo_pago, numero_referencia)
    VALUES (v_id_cuota, p_id_prestamo, p_id_colaborador, p_monto_pagado, p_metodo_pago, p_referencia)
    RETURNING id_pago INTO p_id_pago;

    RAISE NOTICE 'Pago registrado: id_pago=%, cuota=%, monto=Q%',
        p_id_pago, p_numero_cuota, p_monto_pagado;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al registrar pago: %', SQLERRM;
END;
$$;

COMMENT ON PROCEDURE bvg_registrar_pago IS
    'Registra el pago de una cuota validando estado previo';


-- ============================================================
-- PROCEDURE 4: Abrir nueva cuenta para cliente
-- Uso: CALL bvg_abrir_cuenta(id_cliente, tipo, moneda)
-- ============================================================
CREATE OR REPLACE PROCEDURE bvg_abrir_cuenta(
    p_id_cliente   INT,
    p_tipo_cuenta  tipo_cuenta_enum,
    p_moneda       moneda_enum,
    OUT p_id_cuenta INT,
    OUT p_numero    VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    -- Verificar que el cliente existe y está activo
    IF NOT EXISTS (SELECT 1 FROM clientes WHERE id_cliente = p_id_cliente AND activo = TRUE) THEN
        RAISE EXCEPTION 'Cliente % no encontrado o inactivo', p_id_cliente;
    END IF;

    -- Insertar cuenta (trigger genera número)
    INSERT INTO cuentas (id_cliente, numero_cuenta, tipo_cuenta, moneda, saldo)
    VALUES (p_id_cliente, '', p_tipo_cuenta, p_moneda, 0.00)
    RETURNING id_cuenta, numero_cuenta INTO p_id_cuenta, p_numero;

    RAISE NOTICE 'Cuenta % creada para cliente %', p_numero, p_id_cliente;
END;
$$;

COMMENT ON PROCEDURE bvg_abrir_cuenta IS
    'Abre una nueva cuenta bancaria para un cliente existente';


-- ============================================================
-- FUNCIÓN 3: Consulta de saldo de cuenta con validación
-- Uso: SELECT * FROM bvg_consultar_cuenta('CTA-0000000001');
-- ============================================================
CREATE OR REPLACE FUNCTION bvg_consultar_cuenta(p_numero_cuenta VARCHAR)
RETURNS TABLE (
    numero_cuenta   VARCHAR,
    cliente         TEXT,
    tipo_cuenta     TEXT,
    moneda          TEXT,
    saldo           NUMERIC,
    estado          TEXT,
    fecha_apertura  DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.numero_cuenta,
        cl.nombres || ' ' || cl.apellidos,
        c.tipo_cuenta::TEXT,
        c.moneda::TEXT,
        c.saldo,
        c.estado::TEXT,
        c.fecha_apertura
    FROM cuentas c
    JOIN clientes cl ON c.id_cliente = cl.id_cliente
    WHERE c.numero_cuenta = p_numero_cuenta;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cuenta % no encontrada', p_numero_cuenta;
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION bvg_login(
    p_username VARCHAR,
    p_password VARCHAR
)
RETURNS TABLE (
    id_usuario      INT,
    username        VARCHAR,
    rol             TEXT,
    id_cliente      INT,
    id_colaborador  INT,
    valido          BOOLEAN
) AS $$
DECLARE
    v_id_usuario INT;
BEGIN
    -- Registrar intento de acceso en auditoría
    INSERT INTO auditoria (accion, detalle)
    VALUES ('LOGIN_INTENTO', 'Usuario: ' || p_username);
 
    -- Buscar usuario válido y guardar su id
    SELECT u.id_usuario INTO v_id_usuario
    FROM usuarios u
    JOIN roles r ON u.id_rol = r.id_rol
    WHERE u.username      = p_username
      AND u.password_hash = crypt(p_password, u.password_hash)
      AND u.activo        = TRUE;
 
    IF v_id_usuario IS NOT NULL THEN
        -- Actualizar último acceso usando id (sin ambigüedad)
        UPDATE usuarios u
        SET ultimo_acceso     = NOW(),
            intentos_fallidos = 0
        WHERE u.id_usuario = v_id_usuario;
 
        INSERT INTO auditoria (accion, detalle)
        VALUES ('LOGIN_EXITOSO', 'Usuario: ' || p_username);
    ELSE
        -- Incrementar intentos fallidos usando id para evitar ambigüedad
        UPDATE usuarios u
        SET intentos_fallidos = u.intentos_fallidos + 1
        WHERE u.username = p_username;
 
        INSERT INTO auditoria (accion, detalle)
        VALUES ('LOGIN_FALLIDO', 'Usuario: ' || p_username);
    END IF;
 
    -- Retornar resultado
    RETURN QUERY
    SELECT
        u.id_usuario,
        u.username,
        r.nombre::TEXT,
        u.id_cliente,
        u.id_colaborador,
        TRUE
    FROM usuarios u
    JOIN roles r ON u.id_rol = r.id_rol
    WHERE u.id_usuario = v_id_usuario;
END;
$$ LANGUAGE plpgsql;
 
-- Pruebas
SELECT * FROM bvg_login('l.garcia', 'Cliente123!');   -- debe retornar fila
SELECT * FROM bvg_login('l.garcia', 'wrongpass');      -- debe retornar vacío
 
-- Ver auditoría
SELECT accion, detalle, fecha FROM auditoria ORDER BY fecha DESC LIMIT 6;

-- ============================================================
-- PRUEBAS RÁPIDAS
-- ============================================================

-- Probar cálculo de cuota
SELECT bvg_calcular_cuota(25000, 18.00, 12) AS cuota_calculada;

-- Probar login válido
SELECT * FROM bvg_login('l.garcia', 'Cliente123!');

-- Probar login inválido
SELECT * FROM bvg_login('l.garcia', 'wrongpass');

-- Ver auditoría de intentos
SELECT accion, detalle, fecha FROM auditoria ORDER BY fecha DESC LIMIT 10;

-- ============================================================
-- FIN STORED PROCEDURES
-- ============================================================