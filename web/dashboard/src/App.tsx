import React, { useEffect } from 'react';
import { Route, Routes } from 'react-router-dom';
import { authed } from './components/Authed';
import Dashboard from './components/routes/Dashboard';
import Login from './components/routes/Login';
import JoinWaitlist from './components/routes/JoinWaitlist';
import Monitoring from './components/routes/Monitoring';
import MonitoringDayView from './components/routes/MonitoringDayView';
import Profile from './components/routes/Profile';
import Users from './components/routes/Users';
import useWindowWidth from './hooks/window-width';
import { useDispatch, useSelector } from './redux/hooks';
import { windowWidthChanged } from './redux/slice-menu';
import EditUser from './components/routes/EditUser';

const App: React.FC = () => {
  const dispatch = useDispatch();
  const stateWindowWidth = useSelector((state) => state.menu.windowWidth);
  const currentWindowWidth = useWindowWidth();

  useEffect(() => {
    if (stateWindowWidth !== currentWindowWidth) {
      dispatch(windowWidthChanged(currentWindowWidth));
    }
  }, [dispatch, currentWindowWidth, stateWindowWidth]);

  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route path="/join-waitlist" element={<JoinWaitlist />} />
      <Route path="/" element={authed(<Dashboard />)} />
      <Route path="/profile" element={authed(<Profile />)} />
      <Route path="/users" element={authed(<Users />)} />
      <Route path="/monitoring" element={authed(<Monitoring />)} />
      <Route path="/day-view" element={authed(<MonitoringDayView />)} />
      <Route path="/edit-user" element={authed(<EditUser />)} />
    </Routes>
  );
};

export default App;
