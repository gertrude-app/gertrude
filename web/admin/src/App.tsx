import React, { useEffect, useState } from 'react';
import { Navigate, Route, Routes } from 'react-router-dom';
import Layout from './components/Layout';
import Dashboard from './pages/Dashboard';
import Login from './pages/Login';
import ParentDetail from './pages/ParentDetail';
import ParentsList from './pages/ParentsList';
import VerifyToken from './pages/VerifyToken';

const App: React.FC = () => {
  const [token, setToken] = useState<string | null>(() =>
    localStorage.getItem(`admin_token`),
  );

  useEffect(() => {
    const handleStorageChange = (): void => {
      setToken(localStorage.getItem(`admin_token`));
    };
    window.addEventListener(`storage`, handleStorageChange);
    return () => window.removeEventListener(`storage`, handleStorageChange);
  }, []);

  const handleLogin = (newToken: string): void => {
    localStorage.setItem(`admin_token`, newToken);
    setToken(newToken);
  };

  const handleLogout = (): void => {
    localStorage.removeItem(`admin_token`);
    setToken(null);
  };

  if (!token) {
    return (
      <Routes>
        <Route path="/verify/:token" element={<VerifyToken onLogin={handleLogin} />} />
        <Route path="*" element={<Login />} />
      </Routes>
    );
  }

  return (
    <Layout onLogout={handleLogout}>
      <Routes>
        <Route path="/" element={<Dashboard />} />
        <Route path="/parents" element={<ParentsList />} />
        <Route path="/parents/:id" element={<ParentDetail />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </Layout>
  );
};

export default App;
