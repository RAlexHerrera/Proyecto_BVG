-- ============================================================
-- PASO 1: Limpiar datos anteriores (en orden por FK)
-- ============================================================
TRUNCATE TABLE auditoria      RESTART IDENTITY CASCADE;
TRUNCATE TABLE solicitudes    RESTART IDENTITY CASCADE;
TRUNCATE TABLE pagos          RESTART IDENTITY CASCADE;
TRUNCATE TABLE amortizacion   RESTART IDENTITY CASCADE;
TRUNCATE TABLE prestamos      RESTART IDENTITY CASCADE;
TRUNCATE TABLE cuentas        RESTART IDENTITY CASCADE;
TRUNCATE TABLE usuarios       RESTART IDENTITY CASCADE;
TRUNCATE TABLE clientes       RESTART IDENTITY CASCADE;
TRUNCATE TABLE colaboradores  RESTART IDENTITY CASCADE;

-- ============================================================
-- PASO 2: Corregir el trigger para evitar saldo negativo
-- ============================================================
CREATE OR REPLACE FUNCTION actualizar_saldo_prestamo()
RETURNS TRIGGER AS $$
DECLARE
    v_saldo_actual NUMERIC(15,2);
BEGIN
    -- Obtener saldo actual
    SELECT saldo_pendiente INTO v_saldo_actual
    FROM prestamos
    WHERE id_prestamo = NEW.id_prestamo;

    -- Validar que el pago no exceda el saldo
    IF NEW.monto_pagado > v_saldo_actual THEN
        RAISE EXCEPTION 'El monto del pago (%) excede el saldo pendiente (%)',
            NEW.monto_pagado, v_saldo_actual;
    END IF;

    -- Actualizar saldo pendiente
    UPDATE prestamos
    SET saldo_pendiente = saldo_pendiente - NEW.monto_pagado
    WHERE id_prestamo = NEW.id_prestamo;

    -- Marcar cuota como pagada
    UPDATE amortizacion
    SET estado = 'PAGADA',
        fecha_pago_real = CURRENT_DATE
    WHERE id_cuota = NEW.id_cuota;

    -- Si saldo llega a 0 o menos, cerrar préstamo
    UPDATE prestamos
    SET estado = 'PAGADO'
    WHERE id_prestamo = NEW.id_prestamo
      AND saldo_pendiente <= 0;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- PASO 3: Reinsertar todos los datos corregidos
-- ============================================================

-- COLABORADORES
INSERT INTO colaboradores (nombres, apellidos, dpi, puesto, email, telefono) VALUES
    ('Carlos Alejandro', 'Monterroso López', '1234567890101', 'Gerente de Créditos',  'c.monterroso@bvg.com.gt', '55551001'),
    ('María José',       'Pérez Castillo',   '2345678901202', 'Ejecutivo de Cuenta',  'm.perez@bvg.com.gt',       '55551002'),
    ('Roberto Enrique',  'Guzmán Barrios',   '3456789012303', 'Analista de Riesgo',   'r.guzman@bvg.com.gt',      '55551003'),
    ('Ana Lucía',        'Recinos Morales',  '4567890123404', 'Ejecutivo de Cuenta',  'a.recinos@bvg.com.gt',     '55551004'),
    ('Jorge Luis',       'Cifuentes Ruano',  '5678901234505', 'Cajero',               'j.cifuentes@bvg.com.gt',   '55551005');

-- CLIENTES
INSERT INTO clientes (nombres, apellidos, dpi, nit, telefono, email, direccion, fecha_nacimiento) VALUES
    ('Luis Fernando',  'García Méndez',    '1111111111101', '1111111-1', '55561001', 'l.garcia@gmail.com',    'Zona 10, Guatemala',           '1985-03-15'),
    ('Sandra Patricia','López Herrera',    '2222222222202', '2222222-2', '55561002', 's.lopez@gmail.com',     'Zona 15, Guatemala',           '1990-07-22'),
    ('Miguel Ángel',   'Rodríguez Juárez', '3333333333303', '3333333-3', '55561003', 'm.rodriguez@gmail.com', 'Villa Nueva, Guatemala',       '1978-11-05'),
    ('Ana María',      'Herrera Castillo', '4444444444404', '4444444-4', '55561004', 'a.herrera@gmail.com',   'Mixco, Guatemala',             '1995-01-30'),
    ('Carlos Roberto', 'Morales Pérez',    '5555555555505', '5555555-5', '55561005', 'c.morales@gmail.com',   'Zona 1, Guatemala',            '1982-06-18'),
    ('Gabriela Lucía', 'Fuentes Torres',   '6666666666606', '6666666-6', '55561006', 'g.fuentes@gmail.com',   'San Miguel Petapa, Guatemala', '1993-09-25'),
    ('Diego Armando',  'Estrada Gómez',    '7777777777707', '7777777-7', '55561007', 'd.estrada@gmail.com',   'Zona 7, Guatemala',            '1988-04-12'),
    ('Karla Viviana',  'Sánchez López',    '8888888888808', '8888888-8', '55561008', 'k.sanchez@gmail.com',   'Zona 12, Guatemala',           '1996-12-03');

-- USUARIOS
INSERT INTO usuarios (id_rol, id_colaborador, username, password_hash) VALUES
    (1, 1, 'admin.bvg',       crypt('Admin123!',   gen_salt('bf'))),
    (2, 2, 'maria.perez',     crypt('Colab123!',   gen_salt('bf'))),
    (2, 3, 'roberto.guzman',  crypt('Colab123!',   gen_salt('bf'))),
    (2, 4, 'ana.recinos',     crypt('Colab123!',   gen_salt('bf'))),
    (2, 5, 'jorge.cifuentes', crypt('Colab123!',   gen_salt('bf')));

INSERT INTO usuarios (id_rol, id_cliente, username, password_hash) VALUES
    (3, 1, 'l.garcia',    crypt('Cliente123!', gen_salt('bf'))),
    (3, 2, 's.lopez',     crypt('Cliente123!', gen_salt('bf'))),
    (3, 3, 'm.rodriguez', crypt('Cliente123!', gen_salt('bf'))),
    (3, 4, 'a.herrera',   crypt('Cliente123!', gen_salt('bf'))),
    (3, 5, 'c.morales',   crypt('Cliente123!', gen_salt('bf'))),
    (3, 6, 'g.fuentes',   crypt('Cliente123!', gen_salt('bf'))),
    (3, 7, 'd.estrada',   crypt('Cliente123!', gen_salt('bf'))),
    (3, 8, 'k.sanchez',   crypt('Cliente123!', gen_salt('bf')));

-- CUENTAS
INSERT INTO cuentas (id_cliente, numero_cuenta, tipo_cuenta, moneda, saldo) VALUES
    (1, '', 'MONETARIA',   'GTQ', 12500.00),
    (1, '', 'AHORROS',     'GTQ',  8300.50),
    (1, '', 'DOLARES',     'USD',   450.00),
    (2, '', 'MONETARIA',   'GTQ',  5200.75),
    (2, '', 'AHORROS',     'GTQ',  3100.00),
    (3, '', 'MONETARIA',   'GTQ', 28000.00),
    (3, '', 'EMPRESARIAL', 'GTQ', 95000.00),
    (3, '', 'DOLARES',     'USD',  1200.00),
    (4, '', 'AHORROS',     'GTQ',  1800.25),
    (4, '', 'MONETARIA',   'GTQ',  6400.00),
    (5, '', 'MONETARIA',   'GTQ',  9700.50),
    (5, '', 'AHORROS',     'GTQ',  4200.00),
    (6, '', 'AHORROS',     'GTQ',  2500.00),
    (6, '', 'DOLARES',     'USD',   300.00),
    (7, '', 'MONETARIA',   'GTQ', 15300.00),
    (7, '', 'EMPRESARIAL', 'GTQ', 42000.00),
    (8, '', 'AHORROS',     'GTQ',  3900.00),
    (8, '', 'MONETARIA',   'GTQ',  7100.50);

-- ============================================================
-- PRÉSTAMOS
-- saldo_pendiente refleja el estado ACTUAL (ya descontados pagos)
-- para que el trigger no entre en conflicto al insertar pagos del seed
-- ============================================================

-- Préstamo 1: Luis García - Personal 12 meses
-- 5 cuotas pagadas x Q2,291.67 = Q11,458.35 pagado
-- saldo_pendiente real = 25,000 - 11,458.35 = 13,541.65
INSERT INTO prestamos (id_cliente, id_colaborador, numero_prestamo, tipo_prestamo,
    monto_original, saldo_pendiente, tasa_interes, plazo_meses, cuota_mensual,
    estado, fecha_aprobacion, fecha_primer_pago, fecha_vencimiento)
VALUES (1, 2, '', 'PERSONAL', 25000.00, 25000.00, 18.00, 12, 2291.67,
        'ACTIVO', '2024-10-01', '2024-11-01', '2025-10-01');

-- Préstamo 2: Sandra López - Personal 24 meses
INSERT INTO prestamos (id_cliente, id_colaborador, numero_prestamo, tipo_prestamo,
    monto_original, saldo_pendiente, tasa_interes, plazo_meses, cuota_mensual,
    estado, fecha_aprobacion, fecha_primer_pago, fecha_vencimiento)
VALUES (2, 2, '', 'PERSONAL', 15000.00, 15000.00, 20.00, 24, 762.50,
        'ACTIVO', '2024-09-15', '2024-10-15', '2026-09-15');

-- Préstamo 3: Miguel Rodríguez - Hipotecario 120 meses
INSERT INTO prestamos (id_cliente, id_colaborador, numero_prestamo, tipo_prestamo,
    monto_original, saldo_pendiente, tasa_interes, plazo_meses, cuota_mensual,
    estado, fecha_aprobacion, fecha_primer_pago, fecha_vencimiento)
VALUES (3, 1, '', 'HIPOTECARIO', 500000.00, 500000.00, 12.00, 120, 7168.58,
        'ACTIVO', '2024-06-01', '2024-07-01', '2034-06-01');

-- Préstamo 4: Ana Herrera - Personal 6 meses
-- 3 cuotas pagadas x Q1,833.33 = Q5,499.99 pagado
INSERT INTO prestamos (id_cliente, id_colaborador, numero_prestamo, tipo_prestamo,
    monto_original, saldo_pendiente, tasa_interes, plazo_meses, cuota_mensual,
    estado, fecha_aprobacion, fecha_primer_pago, fecha_vencimiento)
VALUES (4, 4, '', 'PERSONAL', 10000.00, 10000.00, 22.00, 6, 1833.33,
        'ACTIVO', '2024-11-01', '2024-12-01', '2025-05-01');

-- Préstamo 5: Carlos Morales - Vehicular 36 meses
-- 7 cuotas pagadas x Q2,773.63 = Q19,415.41 pagado
INSERT INTO prestamos (id_cliente, id_colaborador, numero_prestamo, tipo_prestamo,
    monto_original, saldo_pendiente, tasa_interes, plazo_meses, cuota_mensual,
    estado, fecha_aprobacion, fecha_primer_pago, fecha_vencimiento)
VALUES (5, 3, '', 'VEHICULAR', 80000.00, 80000.00, 15.00, 36, 2773.63,
        'ACTIVO', '2024-08-01', '2024-09-01', '2027-08-01');

-- Préstamo 6: Gabriela Fuentes - Personal PAGADO
INSERT INTO prestamos (id_cliente, id_colaborador, numero_prestamo, tipo_prestamo,
    monto_original, saldo_pendiente, tasa_interes, plazo_meses, cuota_mensual,
    estado, fecha_aprobacion, fecha_primer_pago, fecha_vencimiento)
VALUES (6, 4, '', 'PERSONAL', 5000.00, 0.00, 18.00, 6, 875.00,
        'PAGADO', '2024-01-01', '2024-02-01', '2024-07-01');

-- Préstamo 7: Diego Estrada - Comercial 48 meses
INSERT INTO prestamos (id_cliente, id_colaborador, numero_prestamo, tipo_prestamo,
    monto_original, saldo_pendiente, tasa_interes, plazo_meses, cuota_mensual,
    estado, fecha_aprobacion, fecha_primer_pago, fecha_vencimiento)
VALUES (7, 1, '', 'COMERCIAL', 200000.00, 200000.00, 14.00, 48, 5465.40,
        'ACTIVO', '2024-12-01', '2025-01-01', '2028-12-01');

-- ============================================================
-- AMORTIZACIÓN
-- Se inserta con estado real pero SIN trigger de pagos aún
-- El trigger solo se activa al insertar en tabla pagos
-- ============================================================

-- Préstamo 1 (Luis García, 12 cuotas)
INSERT INTO amortizacion (id_prestamo, numero_cuota, fecha_vencimiento, monto_cuota, capital, interes, saldo_restante, estado) VALUES
    (1,  1, '2024-11-01', 2291.67, 1916.67,  375.00, 23083.33, 'PENDIENTE'),
    (1,  2, '2024-12-01', 2291.67, 1945.42,  346.25, 21137.91, 'PENDIENTE'),
    (1,  3, '2025-01-01', 2291.67, 1974.60,  317.07, 19163.31, 'PENDIENTE'),
    (1,  4, '2025-02-01', 2291.67, 2004.22,  287.45, 17159.09, 'PENDIENTE'),
    (1,  5, '2025-03-01', 2291.67, 2034.28,  257.39, 15124.81, 'PENDIENTE'),
    (1,  6, '2025-04-01', 2291.67, 2064.79,  226.88, 13060.02, 'PENDIENTE'),
    (1,  7, '2025-05-01', 2291.67, 2095.77,  195.90, 10964.25, 'PENDIENTE'),
    (1,  8, '2025-06-01', 2291.67, 2127.20,  164.47,  8837.05, 'PENDIENTE'),
    (1,  9, '2025-07-01', 2291.67, 2159.11,  132.56,  6677.94, 'PENDIENTE'),
    (1, 10, '2025-08-01', 2291.67, 2191.50,  100.17,  4486.44, 'PENDIENTE'),
    (1, 11, '2025-09-01', 2291.67, 2224.37,   67.30,  2262.07, 'PENDIENTE'),
    (1, 12, '2025-10-01', 2295.97, 2262.07,   33.90,     0.00, 'PENDIENTE');

-- Préstamo 4 (Ana Herrera, 6 cuotas)
INSERT INTO amortizacion (id_prestamo, numero_cuota, fecha_vencimiento, monto_cuota, capital, interes, saldo_restante, estado) VALUES
    (4, 1, '2024-12-01', 1833.33, 1650.00, 183.33, 8350.00, 'PENDIENTE'),
    (4, 2, '2025-01-01', 1833.33, 1680.24, 153.09, 6669.76, 'PENDIENTE'),
    (4, 3, '2025-02-01', 1833.33, 1711.05, 122.28, 4958.71, 'PENDIENTE'),
    (4, 4, '2025-03-01', 1833.33, 1742.44,  90.89, 3216.27, 'VENCIDA'),
    (4, 5, '2025-04-01', 1833.33, 1774.42,  58.91, 1441.85, 'PENDIENTE'),
    (4, 6, '2025-05-01', 1836.28, 1809.39,  26.89,    0.00, 'PENDIENTE');

-- Préstamo 5 (Carlos Morales, primeras 8 cuotas)
INSERT INTO amortizacion (id_prestamo, numero_cuota, fecha_vencimiento, monto_cuota, capital, interes, saldo_restante, estado) VALUES
    (5, 1, '2024-09-01', 2773.63, 1773.63, 1000.00, 78226.37, 'PENDIENTE'),
    (5, 2, '2024-10-01', 2773.63, 1795.81,  977.82, 76430.56, 'PENDIENTE'),
    (5, 3, '2024-11-01', 2773.63, 1818.26,  955.37, 74612.30, 'PENDIENTE'),
    (5, 4, '2024-12-01', 2773.63, 1840.97,  932.66, 72771.33, 'PENDIENTE'),
    (5, 5, '2025-01-01', 2773.63, 1863.96,  909.67, 70907.37, 'PENDIENTE'),
    (5, 6, '2025-02-01', 2773.63, 1887.22,  886.41, 69020.15, 'PENDIENTE'),
    (5, 7, '2025-03-01', 2773.63, 1910.76,  862.87, 67109.39, 'PENDIENTE'),
    (5, 8, '2025-04-01', 2773.63, 1934.59,  839.04, 65174.80, 'PENDIENTE');

-- ============================================================
-- PAGOS
-- Al insertar aquí el trigger se activa y:
--   1. Descuenta el monto del saldo_pendiente
--   2. Marca la cuota como PAGADA
-- ============================================================

-- Pagos préstamo 1 (Luis García, cuotas 1-5)
INSERT INTO pagos (id_cuota, id_prestamo, id_colaborador, fecha_pago, monto_pagado, metodo_pago, numero_referencia) VALUES
    (1,  1, 5, '2024-11-01 10:23:00', 2291.67, 'TRANSFERENCIA',    'TRF-20241101-001'),
    (2,  1, 5, '2024-12-02 09:15:00', 2291.67, 'TRANSFERENCIA',    'TRF-20241202-001'),
    (3,  1, 5, '2025-01-03 11:40:00', 2291.67, 'EFECTIVO',          NULL),
    (4,  1, 5, '2025-01-31 14:05:00', 2291.67, 'TRANSFERENCIA',    'TRF-20250131-001'),
    (5,  1, 5, '2025-03-01 10:00:00', 2291.67, 'DEBITO_AUTOMATICO','DEB-20250301-001');

-- Pagos préstamo 4 (Ana Herrera, cuotas 1-3)
INSERT INTO pagos (id_cuota, id_prestamo, id_colaborador, fecha_pago, monto_pagado, metodo_pago, numero_referencia) VALUES
    (13, 4, 4, '2024-12-01 09:00:00', 1833.33, 'EFECTIVO',         NULL),
    (14, 4, 4, '2025-01-02 10:30:00', 1833.33, 'TRANSFERENCIA',    'TRF-20250102-002'),
    (15, 4, 4, '2025-02-03 11:00:00', 1833.33, 'TRANSFERENCIA',    'TRF-20250203-001');

-- Pagos préstamo 5 (Carlos Morales, cuotas 1-7)
INSERT INTO pagos (id_cuota, id_prestamo, id_colaborador, fecha_pago, monto_pagado, metodo_pago, numero_referencia) VALUES
    (19, 5, 5, '2024-09-01 08:30:00', 2773.63, 'DEBITO_AUTOMATICO','DEB-20240901-001'),
    (20, 5, 5, '2024-10-02 08:30:00', 2773.63, 'DEBITO_AUTOMATICO','DEB-20241002-001'),
    (21, 5, 5, '2024-11-01 08:30:00', 2773.63, 'DEBITO_AUTOMATICO','DEB-20241101-001'),
    (22, 5, 5, '2024-12-03 08:30:00', 2773.63, 'DEBITO_AUTOMATICO','DEB-20241203-001'),
    (23, 5, 5, '2025-01-02 08:30:00', 2773.63, 'DEBITO_AUTOMATICO','DEB-20250102-001'),
    (24, 5, 5, '2025-02-01 08:30:00', 2773.63, 'DEBITO_AUTOMATICO','DEB-20250201-001'),
    (25, 5, 5, '2025-03-03 08:30:00', 2773.63, 'DEBITO_AUTOMATICO','DEB-20250303-001');

-- ============================================================
-- SOLICITUDES
-- ============================================================
INSERT INTO solicitudes (id_cliente, id_colaborador, tipo, estado, monto_solicitado, plazo_solicitado, descripcion, fecha_resolucion) VALUES
    (2, 2, 'CREDITO',      'APROBADA',    20000.00, 24,   'Crédito personal para remodelación',           NOW() - INTERVAL '5 days'),
    (4, 4, 'CREDITO',      'EN_REVISION', 50000.00, 36,   'Crédito vehicular',                            NULL),
    (6, 3, 'NUEVA_CUENTA', 'APROBADA',       NULL,  NULL, 'Apertura de cuenta monetaria adicional',       NOW() - INTERVAL '2 days'),
    (8, 2, 'CREDITO',      'PENDIENTE',   35000.00, 48,   'Crédito para negocio propio',                  NULL),
    (1, 1, 'NUEVA_CUENTA', 'RECHAZADA',      NULL,  NULL, 'Cuenta empresarial sin documentos completos',  NOW() - INTERVAL '10 days');

-- ============================================================
-- VERIFICACIÓN FINAL
-- ============================================================
SELECT
    p.numero_prestamo,
    c.nombres || ' ' || c.apellidos     AS cliente,
    p.monto_original,
    p.saldo_pendiente,
    p.monto_original - p.saldo_pendiente AS total_pagado,
    p.estado
FROM prestamos p
JOIN clientes c ON p.id_cliente = c.id_cliente
ORDER BY p.id_prestamo;

-- ============================================================
-- FIN DEL FIX
-- ============================================================