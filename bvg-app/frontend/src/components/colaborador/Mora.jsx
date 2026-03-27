import { useState, useEffect } from 'react';
import { getMora } from '../../services/api';

export default function Mora() {
  const [data,    setData]    = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getMora().then(setData).finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="loading">Cargando clientes en mora...</div>;

  return (
    <div>
      <div className="kpi-grid">
        <div className="kpi">
          <div className="kpi-value" style={{ color:'var(--red)' }}>{data.length}</div>
          <div className="kpi-label">Clientes en mora</div>
        </div>
        <div className="kpi">
          <div className="kpi-value" style={{ color:'var(--red)' }}>
            {data.reduce((s, d) => s + parseInt(d.cuotas_vencidas), 0)}
          </div>
          <div className="kpi-label">Total cuotas vencidas</div>
        </div>
      </div>

      <div className="card">
        <div className="card-title">⚠️ Clientes en Mora</div>
        <div className="table-wrap">
          <table>
            <thead><tr>
              <th>Cliente</th><th>Teléfono</th><th>Email</th>
              <th>Cuotas Vencidas</th><th>Total en Mora</th>
              <th>Primer Vencimiento</th><th>Días Máx. Mora</th>
            </tr></thead>
            <tbody>
              {data.length === 0
                ? <tr><td colSpan={7} className="empty">Sin clientes en mora</td></tr>
                : data.map((d, i) => (
                  <tr key={i}>
                    <td><strong>{d.cliente}</strong></td>
                    <td>{d.telefono}</td>
                    <td>{d.email}</td>
                    <td style={{ color:'var(--red)', fontWeight:700 }}>{d.cuotas_vencidas}</td>
                    <td style={{ color:'var(--red)', fontWeight:700 }}>{d.total_mora}</td>
                    <td>{String(d.primer_vencimiento).slice(0,10)}</td>
                    <td style={{ color:'var(--red)', fontWeight:700 }}>{d.dias_max_mora} días</td>
                  </tr>
                ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
