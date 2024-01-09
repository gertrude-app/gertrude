import React, { useEffect } from 'react';
import { Route, Routes } from 'react-router-dom';
import AuthedChrome from './components/Authed';
import Dashboard from './components/routes/Dashboard';
import Login from './components/routes/Login';
import Logout from './components/routes/Logout';
import MagicLink from './components/routes/MagicLink';
import VerifySignupEmail from './components/routes/VerifySignupEmail';
import CheckoutSuccess from './components/routes/CheckoutSuccess';
import CheckoutCancel from './components/routes/CheckoutCancel';
import SuspendFilter from './components/routes/SuspendFilter';
import ReviewUnlockRequest from './components/routes/UnlockRequest/ReviewUnlockRequest';
import FetchUnlockRequest from './components/routes/UnlockRequest/FetchUnlockRequest';
import EditUnlockRequestKey from './components/routes/UnlockRequest/EditUnlockRequestKey';
import DenyUnlockRequest from './components/routes/UnlockRequest/DenyUnlockRequest';
import SelectUnlockRequestKeychain from './components/routes/UnlockRequest/SelectUnlockRequestKeychain';
import UserUnlockRequests from './components/routes/UnlockRequest/UserUnlockRequests';
import UsersUnlockRequests from './components/routes/UnlockRequest/UsersUnlockRequests';
import AdminSettings from './components/routes/AdminSettings';
import Keychain from './components/routes/Keychain';
import Users from './components/routes/Users';
import UserActivitySummaries from './components/routes/UserActivitySummaries';
import Keychains from './components/routes/Keychains';
import Signup from './components/routes/Signup';
import UserRoute from './components/routes/User';
import CombinedUsersActivitySummaries from './components/routes/CombinedUsersActivitySummaries';
import CombinedUsersActivityFeedRoute from './components/routes/CombinedUsersActivityFeed';
import UserActivityFeed from './components/routes/UserActivityFeed';
import RequestPasswordReset from './components/routes/RequestPasswordReset';
import ChangePassword from './components/routes/ChangePassword';
import Computers from './components/routes/Computers';
import Computer from './components/routes/Computer';
import HollandTalk from './components/routes/HollandTalk';
import UseCaseSurvey from './components/routes/UseCaseSurvey';

const App: React.FC = () => {
  useEffect(() => {
    document.addEventListener(`click`, (e) => {
      if (e.target instanceof HTMLElement && e.target.classList.contains(`ScrollTop`)) {
        window.scrollTo({ top: 0, behavior: `smooth` });
        // retry a couple times, to fix anomalies from (i think) react re-renders
        setTimeout(() => window.scrollTo({ top: 0, behavior: `smooth` }), 150);
        setTimeout(() => window.scrollTo({ top: 0, behavior: `smooth` }), 250);
        setTimeout(() => window.scrollTo({ top: 0 }), 300);
      }
    });
  }, []);

  return (
    <Routes>
      {/* unauthed routes */}
      <Route path="/holland" element={<HollandTalk />} />
      <Route path="/login" element={<Login />} />
      <Route path="/logout" element={<Logout />} />
      <Route path="/otp/:token" element={<MagicLink />} />
      <Route path="/signup" element={<Signup />} />
      <Route path="/use-case" element={<UseCaseSurvey />} />
      <Route path="/verify-signup-email/:token" element={<VerifySignupEmail />} />
      <Route path="/reset-password" element={<RequestPasswordReset />} />
      <Route path="/reset-password/:token" element={<ChangePassword />} />

      {/* authed routes */}
      <Route path="/" element={<AuthedChrome />}>
        <Route index element={<Dashboard />} />
        <Route path="/checkout-success" element={<CheckoutSuccess />} />
        <Route path="/checkout-cancel" element={<CheckoutCancel />} />
        <Route path="settings" element={<AdminSettings />} />
        <Route path="unlock-requests" element={<UsersUnlockRequests />} />

        <Route path="keychains">
          <Route index element={<Keychains />} />
          <Route path=":keychainId" element={<Keychain />} />
        </Route>

        <Route path="computers">
          <Route index element={<Computers />} />
          <Route path=":computerId" element={<Computer />} />
        </Route>

        <Route path="children">
          <Route index element={<Users />} />

          <Route path="activity">
            <Route index element={<CombinedUsersActivitySummaries />} />
            <Route path=":urlDate" element={<CombinedUsersActivityFeedRoute />} />
          </Route>

          <Route path=":userId">
            <Route index element={<UserRoute />} />

            <Route path="suspend-filter-requests/:id" element={<SuspendFilter />} />

            <Route path="unlock-requests">
              <Route index element={<UserUnlockRequests />} />
              <Route path=":id">
                <Route index element={<FetchUnlockRequest />} />
                <Route path="review" element={<ReviewUnlockRequest />} />
                <Route path="select-keychain" element={<SelectUnlockRequestKeychain />} />
                <Route path="edit-key/:keychainId" element={<EditUnlockRequestKey />} />
                <Route path="deny" element={<DenyUnlockRequest />} />
              </Route>
            </Route>

            <Route path="activity">
              <Route index element={<UserActivitySummaries />} />
              <Route path=":urlDate" element={<UserActivityFeed />} />
            </Route>
          </Route>
        </Route>
      </Route>
    </Routes>
  );
};

export default App;
