const express = require('express');
const cors    = require('cors');
const { Pool } = require('pg');

const app  = express();
const PORT = process.env.PORT || 4000;

// ── Conexión a PostgreSQL ─────────────────────────────────
const pool = new Pool({
  host:     process.env.DB_HOST     || 'localhost',
  port:     process.env.DB_PORT     || 5432,
  database: process.env.DB_NAME     || 'bvg',
  user:     process.env.DB_USER     || 'postgres',
  password: process.env.DB_PASSWORD || 'BVG_Pass2024!',
});

pool.connect()
  .then(() => console.log('✅ Conectado a PostgreSQL - BD: bvg'))
  .catch(err => console.error('❌ Error de conexión:', err.message));

// ── Middleware ────────────────────────────────────────────
app.use(cors({ origin: '*' }));
app.use(express.json());

// ── Helper: ejecutar query ────────────────────────────────
const query = (text, params) => pool.query(text, params);

// ============================================================
// AUTH
// ============================================================
app.post('/api/auth/login', async (req, res) => {
  const { username, password } = req.body;
  try {
    const result = await query(
      `SELECT * FROM bvg_login($1, $2)`,
      [username, password]
    );
    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Usuario o contraseña incorrectos' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================================================
// CLIENTE - CUENTAS
// ============================================================
app.get('/api/cliente/:id/cuentas', async (req, res) => {
  try {
    const result = await query(
      `SELECT numero_cuenta, tipo_cuenta, moneda,
              TO_CHAR(saldo, 'FM999,999,990.00') AS saldo,
              estado, fecha_apertura
       FROM cuentas
       WHERE id_cliente = $1 AND estado = 'ACTIVA'
       ORDER BY tipo_cuenta`,
      [req.params.id]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/cliente/:id/cuentas/resumen', async (req, res) => {
  try {
    const result = await query(
      `SELECT tipo_cuenta, moneda,
              COUNT(*) AS cantidad_cuentas,
              TO_CHAR(SUM(saldo), 'FM999,999,990.00') AS saldo_total
       FROM cuentas
       WHERE id_cliente = $1 AND estado = 'ACTIVA'
       GROUP BY tipo_cuenta, moneda
       ORDER BY tipo_cuenta`,
      [req.params.id]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/cliente/abrir-cuenta', async (req, res) => {
  const { id_cliente, tipo_cuenta, moneda } = req.body;
  try {
    const result = await query(
      `SELECT p_id_cuenta, p_numero
       FROM bvg_abrir_cuenta($1, $2::tipo_cuenta_enum, $3::moneda_enum)`,
      [id_cliente, tipo_cuenta, moneda]
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================================================
// CLIENTE - PRÉSTAMOS
// ============================================================
app.get('/api/cliente/:id/prestamos', async (req, res) => {
  try {
    const result = await query(
      `SELECT numero_prestamo, tipo_prestamo,
              TO_CHAR(monto_original,  'FM999,999,990.00') AS monto_original,
              TO_CHAR(saldo_pendiente, 'FM999,999,990.00') AS saldo_pendiente,
              ROUND((saldo_pendiente / monto_original) * 100, 2) AS porcentaje_pendiente,
              tasa_interes, plazo_meses,
              TO_CHAR(cuota_mensual, 'FM999,999,990.00') AS cuota_mensual,
              estado, fecha_aprobacion, fecha_vencimiento, id_prestamo
       FROM prestamos
       WHERE id_cliente = $1
       ORDER BY fecha_aprobacion DESC`,
      [req.params.id]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/prestamo/:id/amortizacion', async (req, res) => {
  try {
    const result = await query(
      `SELECT numero_cuota,
              TO_CHAR(fecha_vencimiento, 'DD/MM/YYYY') AS fecha_vencimiento,
              TO_CHAR(monto_cuota,    'FM999,999,990.00') AS monto_cuota,
              TO_CHAR(capital,        'FM999,999,990.00') AS capital,
              TO_CHAR(interes,        'FM999,999,990.00') AS interes,
              TO_CHAR(saldo_restante, 'FM999,999,990.00') AS saldo_restante,
              estado,
              TO_CHAR(fecha_pago_real, 'DD/MM/YYYY') AS fecha_pago_real
       FROM amortizacion
       WHERE id_prestamo = $1
       ORDER BY numero_cuota`,
      [req.params.id]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================================================
// CLIENTE - PAGOS
// ============================================================
app.get('/api/cliente/:id/pagos', async (req, res) => {
  try {
    const result = await query(
      `SELECT p.numero_prestamo, a.numero_cuota,
              TO_CHAR(pg.fecha_pago,   'DD/MM/YYYY HH24:MI') AS fecha_pago,
              TO_CHAR(pg.monto_pagado, 'FM999,999,990.00')   AS monto_pagado,
              pg.metodo_pago, pg.numero_referencia
       FROM pagos pg
       JOIN amortizacion a ON pg.id_cuota    = a.id_cuota
       JOIN prestamos p    ON pg.id_prestamo = p.id_prestamo
       WHERE p.id_cliente = $1
       ORDER BY pg.fecha_pago DESC`,
      [req.params.id]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/pago/registrar', async (req, res) => {
  const { id_prestamo, numero_cuota, monto_pagado, metodo_pago, referencia, id_colaborador } = req.body;
  try {
    const result = await query(
      `SELECT p_id_pago FROM bvg_registrar_pago(
         $1, $2, $3, $4::metodo_pago_enum, $5, $6
       )`,
      [id_prestamo, numero_cuota, monto_pagado, metodo_pago, referencia || null, id_colaborador]
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================================================
// CLIENTE - SOLICITUDES
// ============================================================
app.get('/api/cliente/:id/solicitudes', async (req, res) => {
  try {
    const result = await query(
      `SELECT tipo, estado,
              TO_CHAR(monto_solicitado, 'FM999,999,990.00') AS monto_solicitado,
              plazo_solicitado,
              TO_CHAR(fecha_solicitud,  'DD/MM/YYYY') AS fecha_solicitud,
              TO_CHAR(fecha_resolucion, 'DD/MM/YYYY') AS fecha_resolucion,
              motivo_rechazo, descripcion
       FROM solicitudes
       WHERE id_cliente = $1
       ORDER BY fecha_solicitud DESC`,
      [req.params.id]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/solicitud/crear', async (req, res) => {
  const { id_cliente, tipo, monto_solicitado, plazo_solicitado, tipo_cuenta_solicitada, descripcion } = req.body;
  try {
    const result = await query(
      `INSERT INTO solicitudes
         (id_cliente, tipo, monto_solicitado, plazo_solicitado, tipo_cuenta_solicitada, descripcion)
       VALUES ($1, $2::tipo_solicitud_enum, $3, $4, $5::tipo_cuenta_enum, $6)
       RETURNING id_solicitud`,
      [id_cliente, tipo, monto_solicitado || null, plazo_solicitado || null, tipo_cuenta_solicitada || null, descripcion]
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================================================
// COLABORADOR
// ============================================================
app.get('/api/colaborador/buscar-cliente', async (req, res) => {
  const { q } = req.query;
  try {
    const result = await query(
      `SELECT id_cliente, nombres || ' ' || apellidos AS nombre,
              dpi, nit, telefono, email, activo,
              TO_CHAR(fecha_registro, 'DD/MM/YYYY') AS fecha_registro
       FROM clientes
       WHERE dpi ILIKE $1
          OR CONCAT(nombres,' ',apellidos) ILIKE $1
          OR email ILIKE $1
       ORDER BY nombres LIMIT 20`,
      [`%${q}%`]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/colaborador/cliente/:id/ficha', async (req, res) => {
  try {
    const cuentas = await query(
      `SELECT 'CUENTA' AS tipo, numero_cuenta AS numero,
              tipo_cuenta::TEXT AS subtipo, moneda::TEXT,
              TO_CHAR(saldo, 'FM999,999,990.00') AS monto,
              estado::TEXT, TO_CHAR(fecha_apertura,'DD/MM/YYYY') AS fecha
       FROM cuentas WHERE id_cliente = $1`,
      [req.params.id]
    );
    const prestamos = await query(
      `SELECT 'PRESTAMO' AS tipo, numero_prestamo AS numero,
              tipo_prestamo::TEXT AS subtipo, 'GTQ' AS moneda,
              TO_CHAR(saldo_pendiente,'FM999,999,990.00') AS monto,
              estado::TEXT, TO_CHAR(fecha_aprobacion,'DD/MM/YYYY') AS fecha
       FROM prestamos WHERE id_cliente = $1`,
      [req.params.id]
    );
    res.json({ cuentas: cuentas.rows, prestamos: prestamos.rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/colaborador/cuotas-por-vencer', async (req, res) => {
  try {
    const result = await query(
      `SELECT cl.nombres || ' ' || cl.apellidos AS cliente,
              cl.telefono, cl.email, p.numero_prestamo, p.tipo_prestamo,
              a.numero_cuota,
              TO_CHAR(a.fecha_vencimiento,'DD/MM/YYYY') AS fecha_vencimiento,
              TO_CHAR(a.monto_cuota,'FM999,999,990.00') AS monto_cuota,
              a.estado, (a.fecha_vencimiento - CURRENT_DATE) AS dias
       FROM amortizacion a
       JOIN prestamos p ON a.id_prestamo = p.id_prestamo
       JOIN clientes cl ON p.id_cliente  = cl.id_cliente
       WHERE a.estado IN ('PENDIENTE','VENCIDA')
         AND a.fecha_vencimiento BETWEEN CURRENT_DATE - INTERVAL '5 days'
                                     AND CURRENT_DATE + INTERVAL '30 days'
       ORDER BY a.fecha_vencimiento`
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/colaborador/mora', async (req, res) => {
  try {
    const result = await query(
      `SELECT cl.nombres || ' ' || cl.apellidos AS cliente,
              cl.telefono, cl.email,
              COUNT(a.id_cuota) AS cuotas_vencidas,
              TO_CHAR(SUM(a.monto_cuota),'FM999,999,990.00') AS total_mora,
              MIN(a.fecha_vencimiento) AS primer_vencimiento,
              MAX(CURRENT_DATE - a.fecha_vencimiento) AS dias_max_mora
       FROM amortizacion a
       JOIN prestamos p ON a.id_prestamo = p.id_prestamo
       JOIN clientes cl ON p.id_cliente  = cl.id_cliente
       WHERE a.estado = 'VENCIDA'
       GROUP BY cl.id_cliente, cl.nombres, cl.apellidos, cl.telefono, cl.email
       ORDER BY dias_max_mora DESC`
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/colaborador/solicitudes', async (req, res) => {
  try {
    const result = await query(
      `SELECT s.id_solicitud, cl.nombres||' '||cl.apellidos AS cliente,
              cl.telefono, s.tipo, s.estado,
              TO_CHAR(s.monto_solicitado,'FM999,999,990.00') AS monto,
              s.plazo_solicitado, s.descripcion,
              TO_CHAR(s.fecha_solicitud,'DD/MM/YYYY HH24:MI') AS fecha_solicitud,
              COALESCE(col.nombres||' '||col.apellidos,'Sin asignar') AS asignado_a
       FROM solicitudes s
       JOIN clientes cl            ON s.id_cliente     = cl.id_cliente
       LEFT JOIN colaboradores col ON s.id_colaborador = col.id_colaborador
       WHERE s.estado IN ('PENDIENTE','EN_REVISION')
       ORDER BY s.fecha_solicitud`
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/colaborador/aprobar-prestamo', async (req, res) => {
  const { id_solicitud, id_colaborador, tasa_interes } = req.body;
  try {
    const result = await query(
      `SELECT p_id_prestamo FROM bvg_aprobar_prestamo($1, $2, $3)`,
      [id_solicitud, id_colaborador, tasa_interes]
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/colaborador/crear-cliente', async (req, res) => {
  const { nombres, apellidos, dpi, nit, telefono, email, direccion, fecha_nacimiento, username, password } = req.body;
  try {
    const result = await query(
      `SELECT p_id_cliente, p_id_usuario FROM bvg_crear_cliente(
         $1,$2,$3,$4,$5,$6,$7,$8,$9,$10
       )`,
      [nombres, apellidos, dpi, nit, telefono, email, direccion, fecha_nacimiento, username, password]
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================================================
// ADMIN - REPORTES
// ============================================================
app.get('/api/admin/resumen', async (req, res) => {
  try {
    const result = await query(
      `SELECT
         (SELECT COUNT(*) FROM clientes  WHERE activo = TRUE)          AS clientes_activos,
         (SELECT COUNT(*) FROM cuentas   WHERE estado = 'ACTIVA')      AS cuentas_activas,
         (SELECT COUNT(*) FROM prestamos WHERE estado = 'ACTIVO')      AS prestamos_activos,
         (SELECT TO_CHAR(COALESCE(SUM(saldo_pendiente),0),'FM999,999,990.00')
          FROM prestamos WHERE estado = 'ACTIVO')                      AS cartera_total,
         (SELECT COUNT(*) FROM amortizacion WHERE estado = 'VENCIDA')  AS cuotas_en_mora,
         (SELECT COUNT(*) FROM solicitudes  WHERE estado = 'PENDIENTE') AS solicitudes_pendientes`
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/admin/cartera', async (req, res) => {
  try {
    const result = await query(
      `SELECT tipo_prestamo,
              COUNT(*) AS cantidad,
              TO_CHAR(SUM(monto_original),  'FM999,999,990.00') AS monto_otorgado,
              TO_CHAR(SUM(saldo_pendiente), 'FM999,999,990.00') AS saldo_pendiente,
              TO_CHAR(AVG(tasa_interes),'FM990.00') || '%'      AS tasa_promedio
       FROM prestamos
       WHERE estado = 'ACTIVO'
       GROUP BY tipo_prestamo
       ORDER BY SUM(saldo_pendiente) DESC`
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/admin/produccion-pagos', async (req, res) => {
  try {
    const result = await query(
      `SELECT TO_CHAR(DATE_TRUNC('month', fecha_pago),'YYYY-MM') AS mes,
              COUNT(*) AS cantidad_pagos,
              TO_CHAR(SUM(monto_pagado),'FM999,999,990.00') AS total_recaudado
       FROM pagos
       GROUP BY DATE_TRUNC('month', fecha_pago)
       ORDER BY mes DESC LIMIT 12`
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/admin/auditoria', async (req, res) => {
  try {
    const result = await query(
      `SELECT accion, detalle, ip_origen,
              TO_CHAR(fecha,'DD/MM/YYYY HH24:MI:SS') AS fecha
       FROM auditoria
       ORDER BY fecha DESC LIMIT 50`
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── Health check ──────────────────────────────────────────
app.get('/api/health', async (req, res) => {
  try {
    await query('SELECT 1');
    res.json({ status: 'ok', db: 'connected', timestamp: new Date() });
  } catch (err) {
    res.status(500).json({ status: 'error', db: 'disconnected' });
  }
});

app.listen(PORT, () => console.log(`🚀 BVG API corriendo en http://localhost:${PORT}`));
