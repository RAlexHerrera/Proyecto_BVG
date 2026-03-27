import { useState, useEffect } from 'react';
import { getCuentas, getResumenCuentas, abrirCuenta } from '../../services/api';

export default function Cuentas({ session }) {
  const [cuentas,  setCuentas]  = useState([]);
  const [resumen,  setResumen]  = useState([]);
  const [loading,  setLoading]  = useState(true);
  const [modal,    setModal]    = useState(false);
  const [form,     setForm]     = useState({ tipo_cuenta: 'AHORROS', moneda: 'GTQ' });
  const [msg,      setMsg]      = useState(null);

  const load = async () => {
    setLoading(true);
    const [c, r] = await Promise.all([
      getCuentas(session.id_cliente),
      getResumenCuentas(session.id_cliente),
    ]);
    setCuentas(c); setResumen(r); setLoading(false);
  };

  useEffect(() => { load(); }, []);

  const handleAbrir = async (e) => {
    e.preventDefault();
    try {
      await abrirCuenta({ id_cliente: session.id_cliente, ...form });
      setMsg({ type: 'success', text: 'Cuenta abierta exitosamente' });
      setModal(false); load();
    } catch (err) {
      setMsg({ type: 'error', text: err.message });
    }
  };

  if (loading) return <div className="loading">Cargando cuentas...</div>;

  return (
    <div>
      <div className="kpi-grid">
        {resumen.map((r, i) => (
          <div className="kpi" key={i}>
            <div className="kpi-value">{r.saldo_total}</div>
            <div className="kpi-label">{r.tipo_cuenta} ({r.moneda})</div>
          </div>
        ))}
      </div>

      {msg && <div className={`alert alert-${msg.type}`}>{msg.text}</div>}

      <div className="card">
        <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center' }}>
          <div className="card-title">Mis Cuentas</div>
          <button className="btn btn-success btn-sm" onClick={() => setModal(true)}>
            + Nueva Cuenta
          </button>
        </div>
        <div className="table-wrap">
          <table>
            <thead><tr>
              <th>Número</th><th>Tipo</th><th>Moneda</th>
              <th>Saldo</th><th>Estado</th><th>Apertura</th>
            </tr></thead>
            <tbody>
              {cuentas.length === 0
                ? <tr><td colSpan={6} className="empty">Sin cuentas activas</td></tr>
                : cuentas.map((c, i) => (
                  <tr key={i}>
                    <td><strong>{c.numero_cuenta}</strong></td>
                    <td>{c.tipo_cuenta}</td>
                    <td>{c.moneda}</td>
                    <td><strong>{c.saldo}</strong></td>
                    <td><span className={`badge badge-${c.estado}`}>{c.estado}</span></td>
                    <td>{String(c.fecha_apertura).slice(0,10)}</td>
                  </tr>
                ))}
            </tbody>
          </table>
        </div>
      </div>

      {modal && (
        <div className="modal-overlay" onClick={() => setModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <div className="modal-title">Abrir Nueva Cuenta</div>
            <form onSubmit={handleAbrir}>
              <div className="form-grid">
                <div className="form-group">
                  <label>Tipo de Cuenta</label>
                  <select value={form.tipo_cuenta}
                    onChange={e => setForm({ ...form, tipo_cuenta: e.target.value })}>
                    {['AHORROS','MONETARIA','DOLARES','EMPRESARIAL'].map(t =>
                      <option key={t}>{t}</option>)}
                  </select>
                </div>
                <div className="form-group">
                  <label>Moneda</label>
                  <select value={form.moneda}
                    onChange={e => setForm({ ...form, moneda: e.target.value })}>
                    <option>GTQ</option><option>USD</option>
                  </select>
                </div>
              </div>
              <div className="modal-actions">
                <button type="button" className="btn btn-outline" onClick={() => setModal(false)}>Cancelar</button>
                <button type="submit" className="btn btn-success">Abrir Cuenta</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
