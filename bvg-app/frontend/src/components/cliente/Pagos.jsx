import { useState, useEffect } from 'react';
import { getPagos } from '../../services/api';

export default function Pagos({ session }) {
  const [pagos,   setPagos]   = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getPagos(session.id_cliente).then(setPagos).finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="loading">Cargando historial...</div>;

  const totalPagado = pagos.length;

  return (
    <div>
      <div className="kpi-grid">
        <div className="kpi">
          <div className="kpi-value">{totalPagado}</div>
          <div className="kpi-label">Pagos realizados</div>
        </div>
      </div>

      <div className="card">
        <div className="card-title">Historial de Pagos</div>
        <div className="table-wrap">
          <table>
            <thead><tr>
              <th>Préstamo</th><th>Cuota #</th><th>Fecha Pago</th>
              <th>Monto</th><th>Método</th><th>Referencia</th>
            </tr></thead>
            <tbody>
              {pagos.length === 0
                ? <tr><td colSpan={6} className="empty">Sin pagos registrados</td></tr>
                : pagos.map((p, i) => (
                  <tr key={i}>
                    <td>{p.numero_prestamo}</td>
                    <td>{p.numero_cuota}</td>
                    <td>{p.fecha_pago}</td>
                    <td><strong>{p.monto_pagado}</strong></td>
                    <td>{p.metodo_pago}</td>
                    <td>{p.numero_referencia || '—'}</td>
                  </tr>
                ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
