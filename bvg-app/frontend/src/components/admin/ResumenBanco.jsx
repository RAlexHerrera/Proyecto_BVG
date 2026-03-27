import { useState, useEffect } from 'react';
import { getResumen } from '../../services/api';

export default function ResumenBanco() {
  const [data,    setData]    = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getResumen().then(setData).finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="loading">Cargando resumen...</div>;
  if (!data)   return null;

  const kpis = [
    { label: 'Clientes Activos',        value: data.clientes_activos,       color: 'var(--blue-mid)' },
    { label: 'Cuentas Activas',         value: data.cuentas_activas,        color: 'var(--green)'    },
    { label: 'Préstamos Activos',       value: data.prestamos_activos,      color: 'var(--blue-dark)'},
    { label: 'Cartera Total',           value: `Q${data.cartera_total}`,    color: 'var(--blue-mid)' },
    { label: 'Cuotas en Mora',          value: data.cuotas_en_mora,         color: 'var(--red)'      },
    { label: 'Solicitudes Pendientes',  value: data.solicitudes_pendientes, color: 'var(--orange)'   },
  ];

  return (
    <div>
      <div className="kpi-grid">
        {kpis.map((k, i) => (
          <div className="kpi" key={i} style={{ borderTopColor: k.color }}>
            <div className="kpi-value" style={{ color: k.color }}>{k.value}</div>
            <div className="kpi-label">{k.label}</div>
          </div>
        ))}
      </div>
    </div>
  );
}
