import React, { useEffect } from 'react';
import { Route, Routes } from 'react-router-dom';
import Chrome from './components/Chrome';
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
      <Route path="/join-waitlist" element={<JoinWaitlist />} />
      <Route path="/" element={withChrome(<Dashboard />)} />
      <Route path="/profile" element={withChrome(<Profile />)} />
      <Route path="/users" element={withChrome(<Users />)} />
      <Route path="/monitoring" element={withChrome(<Monitoring />)} />
      <Route path="/day-view" element={withChrome(<MonitoringDayView />)} />
    </Routes>
  );
};

export default App;

function withChrome(component: JSX.Element): JSX.Element {
  return <Chrome>{component}</Chrome>;
}
