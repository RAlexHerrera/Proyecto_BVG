import { useState } from 'react';
import Cuentas           from './cliente/Cuentas';
import Prestamos         from './cliente/Prestamos';
import Pagos             from './cliente/Pagos';
import Solicitudes       from './cliente/Solicitudes';
import BuscarCliente     from './colaborador/BuscarCliente';
import CuotasPorVencer   from './colaborador/CuotasPorVencer';
import Mora              from './colaborador/Mora';
import GestionSolicitudes from './colaborador/GestionSolicitudes';
import ResumenBanco      from './admin/ResumenBanco';
import CarteraPrestamos  from './admin/CarteraPrestamos';
import ProduccionPagos   from './admin/ProduccionPagos';
import Auditoria         from './admin/Auditoria';

const TABS = {
  CLIENTE: [
    { key: 'cuentas',     label: '💳 Cuentas'     },
    { key: 'prestamos',   label: '📋 Préstamos'    },
    { key: 'pagos',       label: '💰 Pagos'        },
    { key: 'solicitudes', label: '📝 Solicitudes'  },
  ],
  COLABORADOR: [
    { key: 'buscar',      label: '🔍 Buscar Cliente'   },
    { key: 'vencer',      label: '📅 Por Vencer'       },
    { key: 'mora',        label: '⚠️ Mora'             },
    { key: 'solicitudes', label: '📝 Solicitudes'      },
  ],
  ADMIN: [
    { key: 'resumen',     label: '📊 Resumen'          },
    { key: 'cartera',     label: '🏦 Cartera'          },
    { key: 'produccion',  label: '📈 Producción'       },
    { key: 'auditoria',   label: '🔐 Auditoría'        },
  ],
};

export default function Dashboard({ session, onLogout }) {
  const rol  = session.rol;
  const tabs = TABS[rol] || [];
  const [activeTab, setActiveTab] = useState(tabs[0]?.key);

  const renderPanel = () => {
    // ── CLIENTE ──────────────────────────────────────────
    if (rol === 'CLIENTE') {
      if (activeTab === 'cuentas')     return <Cuentas     session={session} />;
      if (activeTab === 'prestamos')   return <Prestamos   session={session} />;
      if (activeTab === 'pagos')       return <Pagos       session={session} />;
      if (activeTab === 'solicitudes') return <Solicitudes session={session} />;
    }
    // ── COLABORADOR ───────────────────────────────────────
    if (rol === 'COLABORADOR') {
      if (activeTab === 'buscar')      return <BuscarCliente      session={session} />;
      if (activeTab === 'vencer')      return <CuotasPorVencer    session={session} />;
      if (activeTab === 'mora')        return <Mora               session={session} />;
      if (activeTab === 'solicitudes') return <GestionSolicitudes session={session} />;
    }
    // ── ADMIN ─────────────────────────────────────────────
    if (rol === 'ADMIN') {
      if (activeTab === 'resumen')     return <ResumenBanco    />;
      if (activeTab === 'cartera')     return <CarteraPrestamos />;
      if (activeTab === 'produccion')  return <ProduccionPagos />;
      if (activeTab === 'auditoria')   return <Auditoria       />;
    }
    return null;
  };

  return (
    <div>
      <nav className="navbar">
        <span className="navbar-brand">🏦 <span>BVG</span> Banco de Vivienda</span>
        <div className="navbar-user">
          <span>{session.username}</span>
          <span className="badge-rol">{rol}</span>
          <button className="btn-logout" onClick={onLogout}>Cerrar sesión</button>
        </div>
      </nav>

      <div className="tabs">
        {tabs.map(t => (
          <button
            key={t.key}
            className={`tab ${activeTab === t.key ? 'active' : ''}`}
            onClick={() => setActiveTab(t.key)}
          >{t.label}</button>
        ))}
      </div>

      <div className="content">
        {renderPanel()}
      </div>
    </div>
  );
}
