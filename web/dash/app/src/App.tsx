import React, { useEffect } from 'react';
import { Route, Routes } from 'react-router-dom';
import AuthedChrome from './components/Authed';
import AdminSettings from './components/routes/AdminSettings';
import ChangePassword from './components/routes/ChangePassword';
import CheckoutCancel from './components/routes/CheckoutCancel';
import CheckoutSuccess from './components/routes/CheckoutSuccess';
import ChildActivityFeed from './components/routes/ChildActivityFeed';
import ChildActivitySummaries from './components/routes/ChildActivitySummaries';
import Computer from './components/routes/Computer';
import Computers from './components/routes/Computers';
import ConferenceEmailForm from './components/routes/ConferenceEmail';
import Dashboard from './components/routes/Dashboard';
import FamilyActivityFeedRoute from './components/routes/FamilyActivityFeed';
import FamilyActivitySummaries from './components/routes/FamilyActivitySummaries';
import Keychain from './components/routes/Keychain';
import Keychains from './components/routes/Keychains';
import Login from './components/routes/Login';
import Logout from './components/routes/Logout';
import MagicLink from './components/routes/MagicLink';
import RequestPasswordReset from './components/routes/RequestPasswordReset';
import SecurityEventsFeed from './components/routes/SecurityEventsFeed';
import Signup from './components/routes/Signup';
import SuspendFilter from './components/routes/SuspendFilter';
import DenyUnlockRequest from './components/routes/UnlockRequest/DenyUnlockRequest';
import EditUnlockRequestKey from './components/routes/UnlockRequest/EditUnlockRequestKey';
import FetchUnlockRequest from './components/routes/UnlockRequest/FetchUnlockRequest';
import ReviewUnlockRequest from './components/routes/UnlockRequest/ReviewUnlockRequest';
import SelectUnlockRequestKeychain from './components/routes/UnlockRequest/SelectUnlockRequestKeychain';
import UserUnlockRequests from './components/routes/UnlockRequest/UserUnlockRequests';
import UsersUnlockRequests from './components/routes/UnlockRequest/UsersUnlockRequests';
import UseCaseSurvey from './components/routes/UseCaseSurvey';
import UserRoute from './components/routes/User';
import Users from './components/routes/Users';
import VerifySignupEmail from './components/routes/VerifySignupEmail';

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
      <Route path="/conf-workshop" element={<ConferenceEmailForm source="workshop" />} />
      <Route path="/conf-booth" element={<ConferenceEmailForm source="booth" />} />
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
        <Route path="security-events" element={<SecurityEventsFeed />} />

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
            <Route index element={<FamilyActivitySummaries />} />
            <Route path=":urlDate" element={<FamilyActivityFeedRoute />} />
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
              <Route index element={<ChildActivitySummaries />} />
              <Route path=":urlDate" element={<ChildActivityFeed />} />
            </Route>
          </Route>
        </Route>
      </Route>
    </Routes>
  );
};

export default App;
