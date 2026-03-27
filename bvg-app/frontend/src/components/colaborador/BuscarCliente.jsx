import { useState } from 'react';
import { buscarCliente, getFichaCliente, crearCliente } from '../../services/api';

export default function BuscarCliente({ session }) {
  const [q,        setQ]        = useState('');
  const [results,  setResults]  = useState([]);
  const [ficha,    setFicha]    = useState(null);
  const [selected, setSelected] = useState(null);
  const [modal,    setModal]    = useState(false);
  const [form,     setForm]     = useState({});
  const [msg,      setMsg]      = useState(null);
  const [loading,  setLoading]  = useState(false);

  const handleBuscar = async (e) => {
    e.preventDefault();
    if (!q.trim()) return;
    setLoading(true);
    const data = await buscarCliente(q);
    setResults(data); setFicha(null); setSelected(null);
    setLoading(false);
  };

  const verFicha = async (cliente) => {
    setSelected(cliente);
    const data = await getFichaCliente(cliente.id_cliente);
    setFicha(data);
  };

  const handleCrear = async (e) => {
    e.preventDefault();
    try {
      await crearCliente(form);
      setMsg({ type: 'success', text: 'Cliente creado exitosamente' });
      setModal(false); setForm({});
    } catch (err) {
      setMsg({ type: 'error', text: err.message });
    }
  };

  return (
    <div>
      {msg && <div className={`alert alert-${msg.type}`}>{msg.text}</div>}

      <div className="card">
        <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:16 }}>
          <div className="card-title" style={{ marginBottom:0 }}>Buscar Cliente</div>
          <button className="btn btn-success btn-sm" onClick={() => setModal(true)}>
            + Nuevo Cliente
          </button>
        </div>
        <form onSubmit={handleBuscar}>
          <div className="search-bar">
            <input value={q} onChange={e => setQ(e.target.value)}
              placeholder="Buscar por DPI, nombre o email..." />
            <button className="btn btn-primary" type="submit">Buscar</button>
          </div>
        </form>

        {loading && <div className="loading">Buscando...</div>}

        {results.length > 0 && (
          <div className="table-wrap">
            <table>
              <thead><tr>
                <th>Nombre</th><th>DPI</th><th>NIT</th>
                <th>Teléfono</th><th>Email</th><th>Estado</th><th></th>
              </tr></thead>
              <tbody>
                {results.map((c, i) => (
                  <tr key={i} style={{ cursor:'pointer' }}>
                    <td><strong>{c.nombre}</strong></td>
                    <td>{c.dpi}</td><td>{c.nit || '—'}</td>
                    <td>{c.telefono}</td><td>{c.email}</td>
                    <td><span className={`badge badge-${c.activo ? 'ACTIVO' : 'CERRADA'}`}>
                      {c.activo ? 'Activo' : 'Inactivo'}
                    </span></td>
                    <td>
                      <button className="btn btn-outline btn-sm" onClick={() => verFicha(c)}>
                        Ver ficha
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {selected && ficha && (
        <div className="card">
          <div className="card-title">Ficha — {selected.nombre}</div>
          <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:20 }}>
            <div>
              <h4 style={{ color:'var(--blue-mid)', marginBottom:10 }}>Cuentas</h4>
              <table>
                <thead><tr><th>Número</th><th>Tipo</th><th>Saldo</th><th>Estado</th></tr></thead>
                <tbody>
                  {ficha.cuentas.map((c,i) => (
                    <tr key={i}>
                      <td>{c.numero}</td><td>{c.subtipo}</td>
                      <td>{c.monto}</td>
                      <td><span className={`badge badge-${c.estado}`}>{c.estado}</span></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <div>
              <h4 style={{ color:'var(--blue-mid)', marginBottom:10 }}>Préstamos</h4>
              <table>
                <thead><tr><th>Número</th><th>Tipo</th><th>Saldo</th><th>Estado</th></tr></thead>
                <tbody>
                  {ficha.prestamos.map((p,i) => (
                    <tr key={i}>
                      <td>{p.numero}</td><td>{p.subtipo}</td>
                      <td>{p.monto}</td>
                      <td><span className={`badge badge-${p.estado}`}>{p.estado}</span></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {modal && (
        <div className="modal-overlay" onClick={() => setModal(false)}>
          <div className="modal" style={{ width:600 }} onClick={e => e.stopPropagation()}>
            <div className="modal-title">Registrar Nuevo Cliente</div>
            <form onSubmit={handleCrear}>
              <div className="form-grid">
                {[
                  ['nombres','Nombres','text'],['apellidos','Apellidos','text'],
                  ['dpi','DPI','text'],['nit','NIT','text'],
                  ['telefono','Teléfono','text'],['email','Email','email'],
                  ['fecha_nacimiento','Fecha Nacimiento','date'],['username','Username','text'],
                  ['password','Contraseña','password'],
                ].map(([key, label, type]) => (
                  <div className="form-group" key={key}>
                    <label>{label}</label>
                    <input type={type} required={['nombres','apellidos','dpi','username','password'].includes(key)}
                      onChange={e => setForm({ ...form, [key]: e.target.value })} />
                  </div>
                ))}
                <div className="form-group" style={{ gridColumn:'1/-1' }}>
                  <label>Dirección</label>
                  <input type="text" onChange={e => setForm({ ...form, direccion: e.target.value })} />
                </div>
              </div>
              <div className="modal-actions">
                <button type="button" className="btn btn-outline" onClick={() => setModal(false)}>Cancelar</button>
                <button type="submit" className="btn btn-success">Crear Cliente</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
