import { useState, useEffect } from 'react';
import { getPrestamos, getAmortizacion } from '../../services/api';

export default function Prestamos({ session }) {
  const [prestamos, setPrestamos] = useState([]);
  const [loading,   setLoading]   = useState(true);
  const [selected,  setSelected]  = useState(null);
  const [amort,     setAmort]     = useState([]);
  const [loadAmort, setLoadAmort] = useState(false);

  useEffect(() => {
    getPrestamos(session.id_cliente).then(setPrestamos).finally(() => setLoading(false));
  }, []);

  const verAmortizacion = async (prestamo) => {
    setSelected(prestamo); setLoadAmort(true);
    const data = await getAmortizacion(prestamo.id_prestamo);
    setAmort(data); setLoadAmort(false);
  };

  if (loading) return <div className="loading">Cargando préstamos...</div>;

  return (
    <div>
      <div className="card">
        <div className="card-title">Mis Préstamos</div>
        <div className="table-wrap">
          <table>
            <thead><tr>
              <th>Número</th><th>Tipo</th><th>Monto Original</th>
              <th>Saldo Pendiente</th><th>% Pendiente</th>
              <th>Tasa</th><th>Cuota</th><th>Estado</th><th></th>
            </tr></thead>
            <tbody>
              {prestamos.length === 0
                ? <tr><td colSpan={9} className="empty">Sin préstamos</td></tr>
                : prestamos.map((p, i) => (
                  <tr key={i}>
                    <td><strong>{p.numero_prestamo}</strong></td>
                    <td>{p.tipo_prestamo}</td>
                    <td>{p.monto_original}</td>
                    <td><strong>{p.saldo_pendiente}</strong></td>
                    <td>
                      <div style={{ display:'flex', alignItems:'center', gap:6 }}>
                        <div style={{
                          width:60, height:8, background:'#eee', borderRadius:4, overflow:'hidden'
                        }}>
                          <div style={{
                            width:`${p.porcentaje_pendiente}%`,
                            height:'100%',
                            background: p.porcentaje_pendiente > 50 ? '#E74C3C' : '#27AE60'
                          }}/>
                        </div>
                        <span>{p.porcentaje_pendiente}%</span>
                      </div>
                    </td>
                    <td>{p.tasa_interes}%</td>
                    <td>{p.cuota_mensual}</td>
                    <td><span className={`badge badge-${p.estado}`}>{p.estado}</span></td>
                    <td>
                      <button className="btn btn-outline btn-sm"
                        onClick={() => verAmortizacion(p)}>
                        Ver cuotas
                      </button>
                    </td>
                  </tr>
                ))}
            </tbody>
          </table>
        </div>
      </div>

      {selected && (
        <div className="modal-overlay" onClick={() => setSelected(null)}>
          <div className="modal" style={{ width: 780 }} onClick={e => e.stopPropagation()}>
            <div className="modal-title">
              Tabla de Amortización — {selected.numero_prestamo}
            </div>
            {loadAmort
              ? <div className="loading">Cargando...</div>
              : (
                <div className="table-wrap">
                  <table>
                    <thead><tr>
                      <th>#</th><th>Vencimiento</th><th>Cuota</th>
                      <th>Capital</th><th>Interés</th><th>Saldo</th>
                      <th>Estado</th><th>Fecha Pago</th>
                    </tr></thead>
                    <tbody>
                      {amort.map((a, i) => (
                        <tr key={i}>
                          <td>{a.numero_cuota}</td>
                          <td>{a.fecha_vencimiento}</td>
                          <td>{a.monto_cuota}</td>
                          <td>{a.capital}</td>
                          <td>{a.interes}</td>
                          <td>{a.saldo_restante}</td>
                          <td><span className={`badge badge-${a.estado}`}>{a.estado}</span></td>
                          <td>{a.fecha_pago_real || '—'}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            <div className="modal-actions">
              <button className="btn btn-outline" onClick={() => setSelected(null)}>Cerrar</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
