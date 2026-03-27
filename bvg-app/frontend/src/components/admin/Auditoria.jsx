import { useState, useEffect } from 'react';
import { getAuditoria } from '../../services/api';

export default function Auditoria() {
  const [data,    setData]    = useState([]);
  const [loading, setLoading] = useState(true);
  const [filtro,  setFiltro]  = useState('');

  useEffect(() => {
    getAuditoria().then(setData).finally(() => setLoading(false));
  }, []);

  const filtered = filtro
    ? data.filter(d =>
        d.accion?.toLowerCase().includes(filtro.toLowerCase()) ||
        d.detalle?.toLowerCase().includes(filtro.toLowerCase()))
    : data;

  const colorAccion = (accion) => {
    if (accion?.includes('EXITOSO')) return 'var(--green)';
    if (accion?.includes('FALLIDO')) return 'var(--red)';
    if (accion?.includes('INTENTO')) return 'var(--orange)';
    return 'var(--blue-mid)';
  };

  if (loading) return <div className="loading">Cargando auditoría...</div>;

  return (
    <div>
      <div className="kpi-grid">
        <div className="kpi">
          <div className="kpi-value">{data.length}</div>
          <div className="kpi-label">Registros totales</div>
        </div>
        <div className="kpi">
          <div className="kpi-value" style={{ color:'var(--red)' }}>
            {data.filter(d => d.accion?.includes('FALLIDO')).length}
          </div>
          <div className="kpi-label">Intentos fallidos</div>
        </div>
        <div className="kpi">
          <div className="kpi-value" style={{ color:'var(--green)' }}>
            {data.filter(d => d.accion?.includes('EXITOSO')).length}
          </div>
          <div className="kpi-label">Logins exitosos</div>
        </div>
      </div>

      <div className="card">
        <div className="card-title">🔐 Log de Auditoría</div>
        <div className="search-bar">
          <input
            value={filtro}
            onChange={e => setFiltro(e.target.value)}
            placeholder="Filtrar por acción o detalle..."
          />
        </div>
        <div className="table-wrap">
          <table>
            <thead><tr>
              <th>Fecha</th><th>Acción</th><th>Detalle</th><th>IP</th>
            </tr></thead>
            <tbody>
              {filtered.length === 0
                ? <tr><td colSpan={4} className="empty">Sin registros</td></tr>
                : filtered.map((d, i) => (
                  <tr key={i}>
                    <td style={{ fontSize:'.82rem', whiteSpace:'nowrap' }}>{d.fecha}</td>
                    <td>
                      <span style={{
                        fontWeight: 700,
                        color: colorAccion(d.accion),
                        fontSize: '.82rem'
                      }}>{d.accion}</span>
                    </td>
                    <td style={{ fontSize:'.85rem' }}>{d.detalle || '—'}</td>
                    <td style={{ fontSize:'.82rem', color:'#999' }}>{d.ip_origen || '—'}</td>
                  </tr>
                ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
