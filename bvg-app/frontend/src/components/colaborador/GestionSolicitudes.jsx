import { useState, useEffect } from 'react';
import { getSolicitudesPendientes, aprobarPrestamo } from '../../services/api';

export default function GestionSolicitudes({ session }) {
  const [data,    setData]    = useState([]);
  const [loading, setLoading] = useState(true);
  const [modal,   setModal]   = useState(null);
  const [tasa,    setTasa]    = useState(18);
  const [msg,     setMsg]     = useState(null);

  const load = () => {
    getSolicitudesPendientes().then(setData).finally(() => setLoading(false));
  };
  useEffect(() => { load(); }, []);

  const handleAprobar = async (e) => {
    e.preventDefault();
    try {
      await aprobarPrestamo({
        id_solicitud:   modal.id_solicitud,
        id_colaborador: session.id_colaborador,
        tasa_interes:   parseFloat(tasa),
      });
      setMsg({ type: 'success', text: `Préstamo aprobado para ${modal.cliente}` });
      setModal(null); load();
    } catch (err) {
      setMsg({ type: 'error', text: err.message });
    }
  };

  if (loading) return <div className="loading">Cargando solicitudes...</div>;

  return (
    <div>
      {msg && <div className={`alert alert-${msg.type}`}>{msg.text}</div>}

      <div className="kpi-grid">
        <div className="kpi">
          <div className="kpi-value">{data.filter(d => d.estado === 'PENDIENTE').length}</div>
          <div className="kpi-label">Pendientes</div>
        </div>
        <div className="kpi">
          <div className="kpi-value" style={{ color:'var(--orange)' }}>
            {data.filter(d => d.estado === 'EN_REVISION').length}
          </div>
          <div className="kpi-label">En Revisión</div>
        </div>
      </div>

      <div className="card">
        <div className="card-title">Solicitudes Pendientes</div>
        <div className="table-wrap">
          <table>
            <thead><tr>
              <th>#</th><th>Cliente</th><th>Tipo</th><th>Estado</th>
              <th>Monto</th><th>Plazo</th><th>Fecha</th><th>Asignado</th><th></th>
            </tr></thead>
            <tbody>
              {data.length === 0
                ? <tr><td colSpan={9} className="empty">Sin solicitudes pendientes</td></tr>
                : data.map((s, i) => (
                  <tr key={i}>
                    <td>{s.id_solicitud}</td>
                    <td><strong>{s.cliente}</strong></td>
                    <td>{s.tipo}</td>
                    <td><span className={`badge badge-${s.estado}`}>{s.estado}</span></td>
                    <td>{s.monto || '—'}</td>
                    <td>{s.plazo_solicitado ? `${s.plazo_solicitado}m` : '—'}</td>
                    <td>{s.fecha_solicitud}</td>
                    <td style={{ fontSize:'.8rem' }}>{s.asignado_a}</td>
                    <td>
                      {s.tipo === 'CREDITO' && (
                        <button className="btn btn-success btn-sm"
                          onClick={() => { setModal(s); setTasa(18); }}>
                          Aprobar
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
            </tbody>
          </table>
        </div>
      </div>

      {modal && (
        <div className="modal-overlay" onClick={() => setModal(null)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <div className="modal-title">Aprobar Préstamo — {modal.cliente}</div>
            <div style={{ background:'var(--gray-light)', borderRadius:8, padding:14, marginBottom:16 }}>
              <p><strong>Monto solicitado:</strong> Q{modal.monto}</p>
              <p><strong>Plazo:</strong> {modal.plazo_solicitado} meses</p>
              <p><strong>Descripción:</strong> {modal.descripcion}</p>
            </div>
            <form onSubmit={handleAprobar}>
              <div className="form-group">
                <label>Tasa de Interés Anual (%)</label>
                <input type="number" step="0.01" min="1" max="60"
                  value={tasa} onChange={e => setTasa(e.target.value)} required />
              </div>
              <div className="modal-actions">
                <button type="button" className="btn btn-outline" onClick={() => setModal(null)}>Cancelar</button>
                <button type="submit" className="btn btn-success">Confirmar Aprobación</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
