import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter, Route, Routes } from 'react-router-dom';
import Dashboard from './components/routes/Dashboard';
import JoinWaitlist from './components/routes/JoinWaitlist';
import Monitoring from './components/routes/Monitoring';
import MonitoringDayView from './components/routes/MonitoringDayView';
import Profile from './components/routes/Profile';
import Users from './components/routes/Users';

ReactDOM.createRoot(document.getElementById(`root`)!).render(
  <React.StrictMode>
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Dashboard />} />
        <Route path="/profile" element={<Profile />} />
        <Route path="/users" element={<Users />} />
        <Route path="/join-waitlist" element={<JoinWaitlist />} />
        <Route path="/monitoring" element={<Monitoring />} />
        <Route path="/day-view" element={<MonitoringDayView />} />
      </Routes>
    </BrowserRouter>
  </React.StrictMode>,
);

// Hot Module Replacement (HMR) - Remove this snippet to remove HMR.
// Learn more: https://www.snowpack.dev/concepts/hot-module-replacement
// prettier-ignore
// eslint-disable-next-line no-constant-condition
if (undefined /* [snowpack] import.meta.hot */) {
  // @ts-ignore
  undefined /* [snowpack] import.meta.hot */
    .accept(); // eslint-disable-line
}
