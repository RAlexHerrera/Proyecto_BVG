import { useState } from 'react';
import { login } from '../services/api';

export default function Login({ onLogin }) {
  const [form, setForm]   = useState({ username: '', password: '' });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError(''); setLoading(true);
    try {
      const user = await login(form.username, form.password);
      onLogin(user);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const fill = (username, password) => setForm({ username, password });

  return (
    <div className="login-wrap">
      <div className="login-card">
        <div className="login-logo">
          <h1>🏦 BVG</h1>
          <p>Banco de Vivienda Guatemala</p>
        </div>

        {error && <div className="alert alert-error">{error}</div>}

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label>Usuario</label>
            <input
              type="text" placeholder="username"
              value={form.username}
              onChange={e => setForm({ ...form, username: e.target.value })}
              required
            />
          </div>
          <div className="form-group">
            <label>Contraseña</label>
            <input
              type="password" placeholder="••••••••"
              value={form.password}
              onChange={e => setForm({ ...form, password: e.target.value })}
              required
            />
          </div>
          <button className="btn btn-primary" type="submit" disabled={loading}>
            {loading ? 'Ingresando...' : 'Ingresar'}
          </button>
        </form>

        <div style={{ marginTop: 20, borderTop: '1px solid #eee', paddingTop: 14 }}>
          <p style={{ fontSize: '.75rem', color: '#999', marginBottom: 8 }}>Accesos de prueba:</p>
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            {[
              { label: 'Admin',       u: 'admin.bvg',   p: 'Admin123!'   },
              { label: 'Colaborador', u: 'maria.perez',  p: 'Colab123!'   },
              { label: 'Cliente',     u: 'l.garcia',     p: 'Cliente123!' },
            ].map(({ label, u, p }) => (
              <button key={u} className="btn btn-outline btn-sm"
                onClick={() => fill(u, p)}>{label}</button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
