import { useState, useEffect } from 'react';
import { getCartera } from '../../services/api';

export default function CarteraPrestamos() {
  const [data, setData]       = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getCartera().then(setData).finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="loading">Cargando cartera...</div>;

  return (
    <div className="card">
      <div className="card-title">Cartera de Préstamos por Tipo</div>
      <div className="table-wrap">
        <table>
          <thead><tr>
            <th>Tipo</th><th>Cantidad</th>
            <th>Monto Otorgado</th><th>Saldo Pendiente</th><th>Tasa Promedio</th>
          </tr></thead>
          <tbody>
            {data.map((d, i) => (
              <tr key={i}>
                <td><strong>{d.tipo_prestamo}</strong></td>
                <td>{d.cantidad}</td>
                <td>{d.monto_otorgado}</td>
                <td><strong>{d.saldo_pendiente}</strong></td>
                <td>{d.tasa_promedio}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
