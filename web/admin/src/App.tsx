import React, { useEffect, useState } from 'react';
import { Navigate, Route, Routes } from 'react-router-dom';
import Layout from './components/Layout';
import AppNaming from './pages/AppNaming';
import AppNamingDetail from './pages/AppNamingDetail';
import AppNamingScan from './pages/AppNamingScan';
import AppRatings from './pages/AppRatings';
import Dashboard from './pages/Dashboard';
import IOSDeviceEvents from './pages/IOSDeviceEvents';
import IOSDevicesList from './pages/IOSDevicesList';
import IOSStats from './pages/IOSStats';
import Login from './pages/Login';
import MusicInstallDetail from './pages/MusicInstallDetail';
import MusicInstallsList from './pages/MusicInstallsList';
import PairqlTelemetry from './pages/PairqlTelemetry';
import ParentDetail from './pages/ParentDetail';
import ParentsList from './pages/ParentsList';
import PodcastInstallDetail from './pages/PodcastInstallDetail';
import PodcastInstallsList from './pages/PodcastInstallsList';
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
        <Route path="/app-naming" element={<AppNaming />} />
        <Route path="/app-naming/scan" element={<AppNamingScan />} />
        <Route path="/app-naming/:bundleId" element={<AppNamingDetail />} />
        <Route path="/blocker-stats" element={<IOSStats />} />
        <Route path="/blocker" element={<IOSDevicesList />} />
        <Route path="/blocker/:vendorId/events" element={<IOSDeviceEvents />} />
        <Route path="/podcasts" element={<PodcastInstallsList />} />
        <Route path="/podcasts/:deviceId/detail" element={<PodcastInstallDetail />} />
        <Route path="/music" element={<MusicInstallsList />} />
        <Route path="/music/:deviceId/detail" element={<MusicInstallDetail />} />
        <Route path="/ratings/:app" element={<AppRatings />} />
        <Route path="/parents" element={<ParentsList />} />
        <Route path="/parents/:id" element={<ParentDetail />} />
        <Route path="/pairql-telemetry" element={<PairqlTelemetry />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </Layout>
  );
};

export default App;
