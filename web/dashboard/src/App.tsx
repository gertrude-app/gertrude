import React, { useEffect } from 'react';
import { Route, Routes } from 'react-router-dom';
import AuthedChrome from './components/Authed';
import Dashboard from './components/routes/Dashboard';
import Login from './components/routes/Login';
import MagicLink from './components/routes/MagicLink';
import JoinWaitlist from './components/routes/JoinWaitlist';
import AdminProfile from './components/routes/AdminProfile';
import Users from './components/routes/Users';
import useWindowWidth from './hooks/window-width';
import { useDispatch, useSelector } from './redux/hooks';
import { windowWidthChanged } from './redux/slice-menu';
import User from './components/routes/User';
import UserActivityOverview from './components/routes/UserActivityOverview';
import UserActivityDay from './components/routes/UserActivityDay';
import Keychains from './components/routes/Keychains';

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
      {/* unauthed routes */}
      <Route path="/login" element={<Login />} />
      <Route path="/otp/:token" element={<MagicLink />} />
      <Route path="/join-waitlist" element={<JoinWaitlist />} />

      {/* authed routes */}
      <Route path="/" element={<AuthedChrome />}>
        <Route index element={<Dashboard />} />
        <Route path="profile" element={<AdminProfile />} />
        <Route path="keychains" element={<Keychains />} />
        <Route path="users">
          <Route index element={<Users />} />
          <Route path=":userId">
            <Route index element={<User />} />
            <Route path="activity">
              <Route index element={<UserActivityOverview />} />
              <Route path=":date" element={<UserActivityDay />} />
            </Route>
          </Route>
        </Route>
      </Route>
    </Routes>
  );
};

export default App;
