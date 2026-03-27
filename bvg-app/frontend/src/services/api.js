const BASE = process.env.REACT_APP_API_URL || '/api';

const req = async (method, path, body) => {
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: { 'Content-Type': 'application/json' },
    body: body ? JSON.stringify(body) : undefined,
  });
  const data = await res.json();
  if (!res.ok) throw new Error(data.error || 'Error en la solicitud');
  return data;
};

// AUTH
export const login = (username, password) =>
  req('POST', '/auth/login', { username, password });

// CLIENTE - CUENTAS
export const getCuentas      = (id) => req('GET', `/cliente/${id}/cuentas`);
export const getResumenCuentas = (id) => req('GET', `/cliente/${id}/cuentas/resumen`);
export const abrirCuenta     = (body) => req('POST', '/cliente/abrir-cuenta', body);

// CLIENTE - PRÉSTAMOS
export const getPrestamos    = (id) => req('GET', `/cliente/${id}/prestamos`);
export const getAmortizacion = (id) => req('GET', `/prestamo/${id}/amortizacion`);

// CLIENTE - PAGOS
export const getPagos        = (id) => req('GET', `/cliente/${id}/pagos`);
export const registrarPago   = (body) => req('POST', '/pago/registrar', body);

// CLIENTE - SOLICITUDES
export const getSolicitudes  = (id) => req('GET', `/cliente/${id}/solicitudes`);
export const crearSolicitud  = (body) => req('POST', '/solicitud/crear', body);

// COLABORADOR
export const buscarCliente   = (q) => req('GET', `/colaborador/buscar-cliente?q=${encodeURIComponent(q)}`);
export const getFichaCliente = (id) => req('GET', `/colaborador/cliente/${id}/ficha`);
export const getCuotasPorVencer = () => req('GET', '/colaborador/cuotas-por-vencer');
export const getMora         = () => req('GET', '/colaborador/mora');
export const getSolicitudesPendientes = () => req('GET', '/colaborador/solicitudes');
export const aprobarPrestamo = (body) => req('POST', '/colaborador/aprobar-prestamo', body);
export const crearCliente    = (body) => req('POST', '/colaborador/crear-cliente', body);

// ADMIN
export const getResumen      = () => req('GET', '/admin/resumen');
export const getCartera      = () => req('GET', '/admin/cartera');
export const getProduccion   = () => req('GET', '/admin/produccion-pagos');
export const getAuditoria    = () => req('GET', '/admin/auditoria');
