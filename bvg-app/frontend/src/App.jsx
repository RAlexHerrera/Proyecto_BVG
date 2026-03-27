import { useState } from 'react';
import Login from './components/Login';
import Dashboard from './components/Dashboard';
import './App.css';

export default function App() {
  const [session, setSession] = useState(null); // { id_usuario, username, rol, id_cliente, id_colaborador }

  return (
    <div className="app">
      {!session
        ? <Login onLogin={setSession} />
        : <Dashboard session={session} onLogout={() => setSession(null)} />
      }
    </div>
  );
}
