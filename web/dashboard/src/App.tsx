import React, { useEffect } from 'react';
import { Route, Routes } from 'react-router-dom';
import Dashboard from './components/routes/Dashboard';
import JoinWaitlist from './components/routes/JoinWaitlist';
import Monitoring from './components/routes/Monitoring';
import MonitoringDayView from './components/routes/MonitoringDayView';
import Profile from './components/routes/Profile';
import Users from './components/routes/Users';
import useWindowWidth from './hooks/window-width';
import { useDispatch, useSelector } from './redux/hooks';
import { windowWidthChanged } from './redux/menu-slice';

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
      <Route path="/" element={<Dashboard />} />
      <Route path="/profile" element={<Profile />} />
      <Route path="/users" element={<Users />} />
      <Route path="/join-waitlist" element={<JoinWaitlist />} />
      <Route path="/monitoring" element={<Monitoring />} />
      <Route path="/day-view" element={<MonitoringDayView />} />
    </Routes>
  );
};

export default App;
