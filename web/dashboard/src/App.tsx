import React, { useEffect } from 'react';
import { Navigate, Route, Routes } from 'react-router-dom';
import { useDispatch, useRedirect, useSelector } from './redux/hooks';
import { windowWidthChanged } from './redux/slice-menu';
import AuthedChrome from './components/Authed';
import Dashboard from './components/routes/Dashboard';
import Login from './components/routes/Login';
import MagicLink from './components/routes/MagicLink';
import VerifySignupEmail from './components/routes/VerifySignupEmail';
import CheckoutSuccess from './components/routes/CheckoutSuccess';
import CheckoutCancel from './components/routes/CheckoutCancel';
import SuspendFilter from './components/routes/SuspendFilter';
import UnlockRequest from './components/routes/UnlockRequest';
import UserUnlockRequests from './components/routes/UserUnlockRequests';
import JoinWaitlist from './components/routes/JoinWaitlist';
import AdminProfile from './components/routes/AdminProfile';
import Keychain from './components/routes/Keychain';
import Users from './components/routes/Users';
import UserActivityOverview from './components/routes/UserActivityOverview';
import UserActivityDay from './components/routes/UserActivityDay';
import Keychains from './components/routes/Keychains';
import Signup from './components/routes/Signup';
import User from './components/routes/User';
import useWindowWidth from './hooks/window-width';

const App: React.FC = () => {
  const dispatch = useDispatch();
  const stateWindowWidth = useSelector((state) => state.menu.windowWidth);
  const currentWindowWidth = useWindowWidth();

  useEffect(() => {
    if (stateWindowWidth !== currentWindowWidth) {
      dispatch(windowWidthChanged(currentWindowWidth));
    }
  }, [dispatch, currentWindowWidth, stateWindowWidth]);

  useEffect(() => {
    document.addEventListener(`click`, (e) => {
      if (e.target instanceof HTMLElement && e.target.classList.contains(`ScrollTop`)) {
        window.scrollTo({ top: 0 });
      }
    });
  }, []);

  const redirect = useRedirect();
  if (redirect) {
    return <Navigate to={redirect} />;
  }

  return (
    <Routes>
      {/* unauthed routes */}
      <Route path="/login" element={<Login />} />
      <Route path="/otp/:token" element={<MagicLink />} />
      <Route path="/join-waitlist" element={<JoinWaitlist />} />
      <Route path="/signup" element={<Signup />} />
      <Route path="/verify-signup-email/:token" element={<VerifySignupEmail />} />
      <Route path="/checkout-success" element={<CheckoutSuccess />} />
      <Route path="/checkout-cancel" element={<CheckoutCancel />} />

      {/* authed routes */}
      <Route path="/" element={<AuthedChrome />}>
        <Route index element={<Dashboard />} />
        <Route path="profile" element={<AdminProfile />} />
        <Route path="suspend-filter-requests/:id" element={<SuspendFilter />} />
        <Route path="unlock-requests/:id" element={<UnlockRequest />} />
        <Route path="keychains">
          <Route index element={<Keychains />} />
          <Route path=":keychainId" element={<Keychain />} />
        </Route>
        <Route path="users">
          <Route index element={<Users />} />
          <Route path=":userId">
            <Route index element={<User />} />
            <Route path="unlock-requests" element={<UserUnlockRequests />} />
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
