import { useState, useEffect } from 'react';
import { getSolicitudes, crearSolicitud } from '../../services/api';

const ESTADO_COLOR = { PENDIENTE:'orange', EN_REVISION:'orange', APROBADA:'green', RECHAZADA:'red' };

export default function Solicitudes({ session }) {
  const [solicitudes, setSolicitudes] = useState([]);
  const [loading,  setLoading]  = useState(true);
  const [modal,    setModal]    = useState(false);
  const [tipo,     setTipo]     = useState('CREDITO');
  const [form,     setForm]     = useState({});
  const [msg,      setMsg]      = useState(null);

  const load = () => {
    getSolicitudes(session.id_cliente).then(setSolicitudes).finally(() => setLoading(false));
  };
  useEffect(() => { load(); }, []);

  const handleEnviar = async (e) => {
    e.preventDefault();
    try {
      await crearSolicitud({ id_cliente: session.id_cliente, tipo, ...form });
      setMsg({ type: 'success', text: 'Solicitud enviada correctamente' });
      setModal(false); setForm({}); load();
    } catch (err) {
      setMsg({ type: 'error', text: err.message });
    }
  };

  if (loading) return <div className="loading">Cargando...</div>;

  return (
    <div>
      {msg && <div className={`alert alert-${msg.type}`}>{msg.text}</div>}

      <div className="card">
        <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center' }}>
          <div className="card-title">Mis Solicitudes</div>
          <button className="btn btn-primary btn-sm" onClick={() => setModal(true)}>
            + Nueva Solicitud
          </button>
        </div>
        <div className="table-wrap">
          <table>
            <thead><tr>
              <th>Tipo</th><th>Estado</th><th>Monto</th>
              <th>Plazo</th><th>Fecha</th><th>Resolución</th><th>Observación</th>
            </tr></thead>
            <tbody>
              {solicitudes.length === 0
                ? <tr><td colSpan={7} className="empty">Sin solicitudes</td></tr>
                : solicitudes.map((s, i) => (
                  <tr key={i}>
                    <td>{s.tipo}</td>
                    <td><span className={`badge badge-${s.estado}`}>{s.estado}</span></td>
                    <td>{s.monto_solicitado || '—'}</td>
                    <td>{s.plazo_solicitado ? `${s.plazo_solicitado} meses` : '—'}</td>
                    <td>{s.fecha_solicitud}</td>
                    <td>{s.fecha_resolucion || '—'}</td>
                    <td style={{ fontSize:'.8rem', color:'#888' }}>{s.motivo_rechazo || s.descripcion || '—'}</td>
                  </tr>
                ))}
            </tbody>
          </table>
        </div>
      </div>

      {modal && (
        <div className="modal-overlay" onClick={() => setModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <div className="modal-title">Nueva Solicitud</div>
            <form onSubmit={handleEnviar}>
              <div className="form-group" style={{ marginBottom:14 }}>
                <label>Tipo de Solicitud</label>
                <select value={tipo} onChange={e => { setTipo(e.target.value); setForm({}); }}>
                  <option value="CREDITO">Crédito</option>
                  <option value="NUEVA_CUENTA">Nueva Cuenta</option>
                </select>
              </div>

              {tipo === 'CREDITO' && (
                <div className="form-grid">
                  <div className="form-group">
                    <label>Monto Solicitado (Q)</label>
                    <input type="number" min="1000" placeholder="25000"
                      onChange={e => setForm({ ...form, monto_solicitado: e.target.value })} required />
                  </div>
                  <div className="form-group">
                    <label>Plazo (meses)</label>
                    <input type="number" min="6" max="360" placeholder="24"
                      onChange={e => setForm({ ...form, plazo_solicitado: e.target.value })} required />
                  </div>
                  <div className="form-group" style={{ gridColumn:'1/-1' }}>
                    <label>Descripción / Motivo</label>
                    <input type="text" placeholder="Ej: Remodelación de vivienda"
                      onChange={e => setForm({ ...form, descripcion: e.target.value })} required />
                  </div>
                </div>
              )}

              {tipo === 'NUEVA_CUENTA' && (
                <div className="form-grid">
                  <div className="form-group">
                    <label>Tipo de Cuenta</label>
                    <select onChange={e => setForm({ ...form, tipo_cuenta_solicitada: e.target.value })}>
                      {['AHORROS','MONETARIA','DOLARES','EMPRESARIAL'].map(t =>
                        <option key={t}>{t}</option>)}
                    </select>
                  </div>
                  <div className="form-group">
                    <label>Descripción</label>
                    <input type="text" placeholder="Motivo de la solicitud"
                      onChange={e => setForm({ ...form, descripcion: e.target.value })} />
                  </div>
                </div>
              )}

              <div className="modal-actions">
                <button type="button" className="btn btn-outline" onClick={() => setModal(false)}>Cancelar</button>
                <button type="submit" className="btn btn-primary">Enviar Solicitud</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
