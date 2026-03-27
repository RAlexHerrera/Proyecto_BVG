import { useState, useEffect } from 'react';
import { getProduccion } from '../../services/api';

export default function ProduccionPagos() {
  const [data, setData]       = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getProduccion().then(setData).finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="loading">Cargando producción...</div>;

  const maxMonto = Math.max(...data.map(d =>
    parseFloat(d.total_recaudado.replace(/,/g,'')) || 0
  ));

  return (
    <div className="card">
      <div className="card-title">Producción Mensual de Pagos</div>
      <div className="table-wrap">
        <table>
          <thead><tr>
            <th>Mes</th><th>Cantidad Pagos</th><th>Total Recaudado</th><th>Tendencia</th>
          </tr></thead>
          <tbody>
            {data.map((d, i) => {
              const val = parseFloat(d.total_recaudado.replace(/,/g,'')) || 0;
              const pct = maxMonto ? (val / maxMonto) * 100 : 0;
              return (
                <tr key={i}>
                  <td><strong>{d.mes}</strong></td>
                  <td>{d.cantidad_pagos}</td>
                  <td><strong>Q{d.total_recaudado}</strong></td>
                  <td>
                    <div style={{ display:'flex', alignItems:'center', gap:8 }}>
                      <div style={{ width:120, height:10, background:'#eee', borderRadius:5, overflow:'hidden' }}>
                        <div style={{ width:`${pct}%`, height:'100%', background:'var(--blue-mid)', borderRadius:5 }} />
                      </div>
                      <span style={{ fontSize:'.8rem', color:'#888' }}>{pct.toFixed(0)}%</span>
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
