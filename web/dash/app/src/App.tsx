import React, { useEffect } from 'react';
import { Navigate, Route, Routes } from 'react-router-dom';
import AuthedChrome from './components/Authed';
import AdminSettings from './components/routes/AdminSettings';
import ChangePassword from './components/routes/ChangePassword';
import CheckoutCancel from './components/routes/CheckoutCancel';
import CheckoutSuccess from './components/routes/CheckoutSuccess';
import ChildActivityFeed from './components/routes/ChildActivityFeed';
import ChildActivitySummaries from './components/routes/ChildActivitySummaries';
import ChildIOSDevicesRoute from './components/routes/ChildIOSDevices';
import ChildMac from './components/routes/ChildMac';
import ClaimBlockerDeviceClaim from './components/routes/ClaimBlockerDevice/Claim';
import ClaimBlockerDeviceDone from './components/routes/ClaimBlockerDevice/Done';
import ClaimMusicDeviceClaim from './components/routes/ClaimMusicDevice/Claim';
import ClaimMusicDeviceDone from './components/routes/ClaimMusicDevice/Done';
import ClaimMusicDevicePayment from './components/routes/ClaimMusicDevice/Payment';
import ClaimPodcastsDeviceClaim from './components/routes/ClaimPodcastsDevice/Claim';
import ClaimPodcastsDeviceDone from './components/routes/ClaimPodcastsDevice/Done';
import Computer from './components/routes/Computer';
import Computers from './components/routes/Computers';
import ConferenceEmailForm from './components/routes/ConferenceEmail';
import Dashboard from './components/routes/Dashboard';
import FamilyActivityFeedRoute from './components/routes/FamilyActivityFeed';
import FamilyActivitySummaries from './components/routes/FamilyActivitySummaries';
import IOSDevice from './components/routes/IOSDevice';
import Keychain from './components/routes/Keychain';
import Keychains from './components/routes/Keychains';
import LinkExpired from './components/routes/LinkExpired';
import Login from './components/routes/Login';
import Logout from './components/routes/Logout';
import MagicLink from './components/routes/MagicLink';
import ReferralSurvey from './components/routes/ReferralSurvey';
import RequestPasswordReset from './components/routes/RequestPasswordReset';
import SecurityEventsFeed from './components/routes/SecurityEventsFeed';
import Signup from './components/routes/Signup';
import SuperviseDevice from './components/routes/SuperviseDevice';
import SuperviseDeviceClaim from './components/routes/SuperviseDevice/Claim';
import SuperviseDeviceDone from './components/routes/SuperviseDevice/Done';
import SuperviseDeviceDownloadHelper from './components/routes/SuperviseDevice/DownloadHelper';
import SuperviseDeviceLaunchHelper from './components/routes/SuperviseDevice/LaunchHelper';
import SuperviseDevicePayment from './components/routes/SuperviseDevice/Payment';
import RequirePaidSupervision from './components/routes/SuperviseDevice/RequirePaidSupervision';
import SuperviseDeviceSupervise from './components/routes/SuperviseDevice/Supervise';
import SuspendFilter from './components/routes/SuspendFilter';
import UserUnlockRequests from './components/routes/UnlockRequest/UserUnlockRequests';
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
      <Route path="/referral-survey" element={<ReferralSurvey />} />
      <Route path="/verify-signup-email/:token" element={<VerifySignupEmail />} />
      <Route path="/reset-password" element={<RequestPasswordReset />} />
      <Route path="/reset-password/:token" element={<ChangePassword />} />
      <Route path="/link-expired" element={<LinkExpired />} />

      {/* authed routes */}
      <Route path="/" element={<AuthedChrome />}>
        <Route index element={<Dashboard />} />

        <Route path="supervise-device/:code" element={<SuperviseDevice />}>
          <Route path="claim" element={<SuperviseDeviceClaim />} />
          <Route path="payment" element={<SuperviseDevicePayment />} />
          <Route element={<RequirePaidSupervision />}>
            <Route path="download-helper" element={<SuperviseDeviceDownloadHelper />} />
            <Route path="launch-helper" element={<SuperviseDeviceLaunchHelper />} />
            <Route path="supervise" element={<SuperviseDeviceSupervise />} />
            <Route path="done" element={<SuperviseDeviceDone />} />
          </Route>
        </Route>
        <Route
          path="claim-podcasts-device/:code/claim"
          element={<ClaimPodcastsDeviceClaim />}
        />
        <Route
          path="claim-podcasts-device/:code/done"
          element={<ClaimPodcastsDeviceDone />}
        />
        <Route
          path="claim-am-device/:code/claim"
          element={<ClaimPodcastsDeviceClaim />}
        />
        <Route path="claim-am-device/:code/done" element={<ClaimPodcastsDeviceDone />} />
        <Route
          path="claim-blocker-device/:code/claim"
          element={<ClaimBlockerDeviceClaim />}
        />
        <Route
          path="claim-blocker-device/:code/done"
          element={<ClaimBlockerDeviceDone />}
        />
        <Route
          path="claim-music-device/:code/claim"
          element={<ClaimMusicDeviceClaim />}
        />
        <Route
          path="claim-music-device/:code/payment"
          element={<ClaimMusicDevicePayment />}
        />
        <Route path="claim-music-device/:code/done" element={<ClaimMusicDeviceDone />} />
        <Route path="/checkout-success" element={<CheckoutSuccess />} />
        <Route path="/checkout-cancel" element={<CheckoutCancel />} />
        <Route path="settings" element={<AdminSettings />} />
        {/* @deprecated safe to remove May 2026 */}
        <Route path="unlock-requests" element={<Navigate to="/" replace />} />
        <Route path="security-events" element={<SecurityEventsFeed />} />

        <Route path="keychains">
          <Route index element={<Keychains />} />
          <Route path=":keychainId" element={<Keychain />} />
        </Route>

        <Route path="devices">
          <Route index element={<Computers />} />
          <Route path=":computerId" element={<Computer />} />
        </Route>
        <Route path="computers/*" element={<Navigate to="/devices" replace />} />
        <Route path="ios-devices/*" element={<Navigate to="/devices" replace />} />

        <Route path="children">
          <Route index element={<Users />} />

          <Route path="activity">
            <Route index element={<FamilyActivitySummaries />} />
            <Route path=":urlDate" element={<FamilyActivityFeedRoute />} />
          </Route>

          <Route path=":userId">
            <Route index element={<UserRoute />} />
            <Route path="mac" element={<ChildMac />} />

            <Route path="ios-devices">
              <Route index element={<ChildIOSDevicesRoute />} />
              <Route path=":deviceId" element={<IOSDevice />} />
            </Route>

            <Route path="suspend-filter-requests/:id" element={<SuspendFilter />} />

            <Route path="unlock-requests">
              <Route index element={<UserUnlockRequests />} />
              {/* @deprecated safe to remove May 2026 */}
              <Route path=":id/*" element={<Navigate to=".." replace />} />
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
