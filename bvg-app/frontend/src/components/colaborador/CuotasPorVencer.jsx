// ── CuotasPorVencer ──────────────────────────────────────────
import { useState, useEffect } from 'react';
import { getCuotasPorVencer } from '../../services/api';

export default function CuotasPorVencer() {
  const [data,    setData]    = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getCuotasPorVencer().then(setData).finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="loading">Cargando...</div>;

  const vencidas  = data.filter(d => d.estado === 'VENCIDA');
  const proximas  = data.filter(d => d.estado === 'PENDIENTE');

  return (
    <div>
      <div className="kpi-grid">
        <div className="kpi">
          <div className="kpi-value" style={{ color:'var(--red)' }}>{vencidas.length}</div>
          <div className="kpi-label">Cuotas Vencidas</div>
        </div>
        <div className="kpi">
          <div className="kpi-value" style={{ color:'var(--orange)' }}>{proximas.length}</div>
          <div className="kpi-label">Por Vencer (30 días)</div>
        </div>
      </div>

      <div className="card">
        <div className="card-title">Cuotas Vencidas y Por Vencer</div>
        <div className="table-wrap">
          <table>
            <thead><tr>
              <th>Cliente</th><th>Teléfono</th><th>Préstamo</th>
              <th>Cuota #</th><th>Vencimiento</th><th>Monto</th>
              <th>Estado</th><th>Días</th>
            </tr></thead>
            <tbody>
              {data.length === 0
                ? <tr><td colSpan={8} className="empty">Sin cuotas próximas</td></tr>
                : data.map((d, i) => (
                  <tr key={i}>
                    <td><strong>{d.cliente}</strong></td>
                    <td>{d.telefono}</td>
                    <td>{d.numero_prestamo}</td>
                    <td>{d.numero_cuota}</td>
                    <td>{d.fecha_vencimiento}</td>
                    <td>{d.monto_cuota}</td>
                    <td><span className={`badge badge-${d.estado}`}>{d.estado}</span></td>
                    <td style={{ color: d.dias < 0 ? 'var(--red)' : d.dias < 7 ? 'var(--orange)' : 'inherit',
                                 fontWeight: d.dias < 7 ? 700 : 400 }}>
                      {d.dias < 0 ? `${Math.abs(d.dias)} días atrás` : `en ${d.dias} días`}
                    </td>
                  </tr>
                ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
