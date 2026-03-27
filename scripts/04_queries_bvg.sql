-- ============================================================
--  Consultas optimizadas
--
-- ⚠️  Ejecutar conectado a la BD 'bvg'
-- ============================================================


-- ============================================================
-- BLOQUE 1: CONSULTAS DE CLIENTE
-- (Lo que ve el cliente desde su portal)
-- ============================================================

-- Q01: Todas las cuentas de un cliente con saldo actual
SELECT
    numero_cuenta,
    tipo_cuenta,
    moneda,
    TO_CHAR(saldo, 'FM999,999,990.00')  AS saldo,
    estado,
    fecha_apertura
FROM cuentas
WHERE id_cliente = 1          -- Reemplazar con el id del cliente
  AND estado = 'ACTIVA'
ORDER BY tipo_cuenta;


-- Q02: Resumen financiero del cliente (total por tipo de cuenta)
SELECT
    tipo_cuenta,
    moneda,
    COUNT(*)                                    AS cantidad_cuentas,
    TO_CHAR(SUM(saldo), 'FM999,999,990.00')    AS saldo_total
FROM cuentas
WHERE id_cliente = 1
  AND estado = 'ACTIVA'
GROUP BY tipo_cuenta, moneda
ORDER BY tipo_cuenta;


-- Q03: Todos los préstamos activos de un cliente
SELECT
    numero_prestamo,
    tipo_prestamo,
    TO_CHAR(monto_original,   'FM999,999,990.00')  AS monto_original,
    TO_CHAR(saldo_pendiente,  'FM999,999,990.00')  AS saldo_pendiente,
    ROUND((saldo_pendiente / monto_original) * 100, 2) || '%' AS porcentaje_pendiente,
    tasa_interes || '%'                             AS tasa_anual,
    TO_CHAR(cuota_mensual,    'FM999,999,990.00')  AS cuota_mensual,
    plazo_meses,
    estado,
    fecha_aprobacion,
    fecha_vencimiento
FROM prestamos
WHERE id_cliente = 1
ORDER BY fecha_aprobacion DESC;


-- Q04: Tabla de amortización completa de un préstamo
SELECT
    numero_cuota,
    TO_CHAR(fecha_vencimiento, 'DD/MM/YYYY')        AS vencimiento,
    TO_CHAR(monto_cuota,  'FM999,999,990.00')       AS cuota,
    TO_CHAR(capital,      'FM999,999,990.00')       AS capital,
    TO_CHAR(interes,      'FM999,999,990.00')       AS interes,
    TO_CHAR(saldo_restante, 'FM999,999,990.00')     AS saldo_restante,
    estado,
    TO_CHAR(fecha_pago_real, 'DD/MM/YYYY')          AS fecha_pago
FROM amortizacion
WHERE id_prestamo = 1          -- Reemplazar con el id del préstamo
ORDER BY numero_cuota;


-- Q05: Historial de pagos de un cliente (todos sus préstamos)
SELECT
    p.numero_prestamo,
    a.numero_cuota,
    TO_CHAR(pg.fecha_pago,    'DD/MM/YYYY HH24:MI') AS fecha_pago,
    TO_CHAR(pg.monto_pagado,  'FM999,999,990.00')   AS monto_pagado,
    pg.metodo_pago,
    pg.numero_referencia
FROM pagos pg
JOIN amortizacion a  ON pg.id_cuota     = a.id_cuota
JOIN prestamos p     ON pg.id_prestamo  = p.id_prestamo
WHERE p.id_cliente = 1
ORDER BY pg.fecha_pago DESC;


-- Q06: Próximas cuotas a pagar del cliente (próximos 60 días)
SELECT
    p.numero_prestamo,
    p.tipo_prestamo,
    a.numero_cuota,
    TO_CHAR(a.fecha_vencimiento, 'DD/MM/YYYY')      AS vence,
    TO_CHAR(a.monto_cuota, 'FM999,999,990.00')      AS monto,
    a.estado,
    (a.fecha_vencimiento - CURRENT_DATE)            AS dias_restantes
FROM amortizacion a
JOIN prestamos p ON a.id_prestamo = p.id_prestamo
WHERE p.id_cliente = 1
  AND a.estado IN ('PENDIENTE', 'VENCIDA')
  AND a.fecha_vencimiento <= CURRENT_DATE + INTERVAL '60 days'
ORDER BY a.fecha_vencimiento;


-- Q07: Estado de solicitudes del cliente
SELECT
    tipo,
    estado,
    TO_CHAR(monto_solicitado, 'FM999,999,990.00')   AS monto,
    plazo_solicitado,
    TO_CHAR(fecha_solicitud,  'DD/MM/YYYY')         AS fecha_solicitud,
    TO_CHAR(fecha_resolucion, 'DD/MM/YYYY')         AS fecha_resolucion,
    motivo_rechazo
FROM solicitudes
WHERE id_cliente = 1
ORDER BY fecha_solicitud DESC;


-- ============================================================
-- BLOQUE 2: CONSULTAS DE COLABORADOR
-- (Panel de gestión del empleado)
-- ============================================================

-- Q08: Buscar cliente por DPI, nombre o email
SELECT
    id_cliente,
    nombres || ' ' || apellidos     AS cliente,
    dpi,
    nit,
    telefono,
    email,
    direccion,
    activo,
    TO_CHAR(fecha_registro, 'DD/MM/YYYY') AS cliente_desde
FROM clientes
WHERE
    dpi    ILIKE '%1111%'           -- Reemplazar con el criterio de búsqueda
    OR CONCAT(nombres, ' ', apellidos) ILIKE '%Luis%'
    OR email ILIKE '%garcia%'
ORDER BY nombres;


-- Q09: Ficha completa de un cliente (cuentas + préstamos)
SELECT
    'CUENTA' AS tipo_producto,
    numero_cuenta AS numero,
    tipo_cuenta::TEXT AS subtipo,
    moneda::TEXT,
    TO_CHAR(saldo, 'FM999,999,990.00') AS monto,
    estado::TEXT,
    TO_CHAR(fecha_apertura, 'DD/MM/YYYY') AS fecha
FROM cuentas
WHERE id_cliente = 1

UNION ALL

SELECT
    'PRESTAMO',
    numero_prestamo,
    tipo_prestamo::TEXT,
    'GTQ',
    TO_CHAR(saldo_pendiente, 'FM999,999,990.00'),
    estado::TEXT,
    TO_CHAR(fecha_aprobacion, 'DD/MM/YYYY')
FROM prestamos
WHERE id_cliente = 1
ORDER BY 1, 7;


-- Q10: Cuotas vencidas o por vencer en los próximos 30 días (todos los clientes)
SELECT
    cl.nombres || ' ' || cl.apellidos  AS cliente,
    cl.telefono,
    cl.email,
    p.numero_prestamo,
    p.tipo_prestamo,
    a.numero_cuota,
    TO_CHAR(a.fecha_vencimiento, 'DD/MM/YYYY')  AS vencimiento,
    TO_CHAR(a.monto_cuota, 'FM999,999,990.00')  AS monto_cuota,
    a.estado,
    (a.fecha_vencimiento - CURRENT_DATE)        AS dias
FROM amortizacion a
JOIN prestamos p ON a.id_prestamo = p.id_prestamo
JOIN clientes cl ON p.id_cliente  = cl.id_cliente
WHERE a.estado IN ('PENDIENTE', 'VENCIDA')
  AND a.fecha_vencimiento BETWEEN CURRENT_DATE - INTERVAL '5 days'
                               AND CURRENT_DATE + INTERVAL '30 days'
ORDER BY a.fecha_vencimiento;


-- Q11: Clientes con cuotas vencidas (mora)
SELECT
    cl.nombres || ' ' || cl.apellidos      AS cliente,
    cl.telefono,
    cl.email,
    COUNT(a.id_cuota)                       AS cuotas_vencidas,
    TO_CHAR(SUM(a.monto_cuota), 'FM999,999,990.00') AS total_en_mora,
    MIN(a.fecha_vencimiento)                AS primer_vencimiento,
    MAX(CURRENT_DATE - a.fecha_vencimiento) AS dias_max_mora
FROM amortizacion a
JOIN prestamos p ON a.id_prestamo = p.id_prestamo
JOIN clientes cl ON p.id_cliente  = cl.id_cliente
WHERE a.estado = 'VENCIDA'
GROUP BY cl.id_cliente, cl.nombres, cl.apellidos, cl.telefono, cl.email
ORDER BY dias_max_mora DESC;


-- Q12: Solicitudes pendientes de atender
SELECT
    s.id_solicitud,
    cl.nombres || ' ' || cl.apellidos      AS cliente,
    cl.telefono,
    s.tipo,
    s.estado,
    TO_CHAR(s.monto_solicitado, 'FM999,999,990.00') AS monto,
    s.plazo_solicitado,
    s.descripcion,
    TO_CHAR(s.fecha_solicitud, 'DD/MM/YYYY HH24:MI') AS fecha_solicitud,
    COALESCE(col.nombres || ' ' || col.apellidos, 'Sin asignar') AS asignado_a
FROM solicitudes s
JOIN clientes cl             ON s.id_cliente     = cl.id_cliente
LEFT JOIN colaboradores col  ON s.id_colaborador = col.id_colaborador
WHERE s.estado IN ('PENDIENTE', 'EN_REVISION')
ORDER BY s.fecha_solicitud;


-- Q13: Registrar un nuevo pago (transacción segura)
BEGIN;

    INSERT INTO pagos (id_cuota, id_prestamo, id_colaborador, monto_pagado, metodo_pago, numero_referencia)
    VALUES (
        6,                      -- id_cuota  (cuota 6 del préstamo 1)
        1,                      -- id_prestamo
        5,                      -- id_colaborador que registra
        2291.67,                -- monto_pagado
        'EFECTIVO',             -- metodo_pago
        NULL                    -- numero_referencia (opcional)
    );

    -- Verificar que el saldo quedó correcto
    SELECT numero_prestamo, saldo_pendiente, estado
    FROM prestamos WHERE id_prestamo = 1;

COMMIT;


-- ============================================================
-- BLOQUE 3: REPORTES Y ESTADÍSTICAS
-- ============================================================

-- Q14: Resumen general del banco
SELECT
    (SELECT COUNT(*) FROM clientes WHERE activo = TRUE)             AS clientes_activos,
    (SELECT COUNT(*) FROM cuentas  WHERE estado = 'ACTIVA')         AS cuentas_activas,
    (SELECT COUNT(*) FROM prestamos WHERE estado = 'ACTIVO')        AS prestamos_activos,
    (SELECT TO_CHAR(SUM(saldo_pendiente), 'FM999,999,990.00')
     FROM prestamos WHERE estado = 'ACTIVO')                        AS cartera_total,
    (SELECT COUNT(*) FROM amortizacion WHERE estado = 'VENCIDA')    AS cuotas_en_mora,
    (SELECT COUNT(*) FROM solicitudes  WHERE estado = 'PENDIENTE')  AS solicitudes_pendientes;


-- Q15: Cartera de préstamos por tipo
SELECT
    tipo_prestamo,
    COUNT(*)                                                AS cantidad,
    TO_CHAR(SUM(monto_original),  'FM999,999,990.00')     AS monto_total_otorgado,
    TO_CHAR(SUM(saldo_pendiente), 'FM999,999,990.00')     AS saldo_pendiente_total,
    TO_CHAR(AVG(tasa_interes), 'FM990.00') || '%'         AS tasa_promedio
FROM prestamos
WHERE estado = 'ACTIVO'
GROUP BY tipo_prestamo
ORDER BY SUM(saldo_pendiente) DESC;


-- Q16: Producción mensual de pagos (últimos 6 meses)
SELECT
    TO_CHAR(DATE_TRUNC('month', fecha_pago), 'YYYY-MM')    AS mes,
    COUNT(*)                                                AS cantidad_pagos,
    TO_CHAR(SUM(monto_pagado), 'FM999,999,990.00')         AS total_recaudado
FROM pagos
WHERE fecha_pago >= NOW() - INTERVAL '6 months'
GROUP BY DATE_TRUNC('month', fecha_pago)
ORDER BY mes DESC;


-- Q17: Validar login de usuario (uso desde la app)
-- Devuelve el usuario si las credenciales son correctas
SELECT
    u.id_usuario,
    u.username,
    r.nombre        AS rol,
    u.id_cliente,
    u.id_colaborador,
    u.activo
FROM usuarios u
JOIN roles r ON u.id_rol = r.id_rol
WHERE u.username     = 'l.garcia'          -- Reemplazar con el username
  AND u.password_hash = crypt('Cliente123!', u.password_hash)   -- Reemplazar con la contraseña
  AND u.activo = TRUE;


-- ============================================================
-- FIN DE QUERIES PRINCIPALES
-- ============================================================