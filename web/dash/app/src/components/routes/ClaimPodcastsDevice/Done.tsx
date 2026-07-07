import { PodcastsDoneScreen, ScreenShell } from '@dash/components';
import React from 'react';
import { Navigate, useLocation, useNavigate, useParams } from 'react-router-dom';
import type { T } from '@shared/pairql/dashboard';
import { podcastsDoneVariant } from './podcastsDoneVariant';

export interface PodcastsDoneNavState {
  subscription: T.ClaimAmDevice.Output[`subscription`];
  childName: string;
  childId: string;
  deviceId: string;
  modelName: string;
  iosVersion: string;
}

const ClaimPodcastsDeviceDone: React.FC = () => {
  const { code = `` } = useParams<{ code: string }>();
  const navigate = useNavigate();
  const location = useLocation();
  const state = location.state as PodcastsDoneNavState | null;

  // reached without nav state (e.g. refresh / direct link) — bounce back through
  // claim, which re-fetches and re-routes here with the carried subscription state
  if (!state) {
    return <Navigate to={`/claim-podcasts-device/${code}/claim`} replace />;
  }

  const { subscription, childName, childId, deviceId, modelName, iosVersion } = state;
  const deviceType = modelName.toLowerCase().includes(`ipad`) ? `iPad` : `iPhone`;
  const { variant, accessEndsAt, trialDaysRemaining, subscribeUrl, showSubscribe } =
    podcastsDoneVariant(subscription);

  const handleSubscribe = (): void => {
    const url = subscribeUrl ?? `/settings`;
    if (url.startsWith(`http`)) {
      window.location.href = url;
    } else {
      navigate(url);
    }
  };

  return (
    <ScreenShell title={`${deviceType} Connected`}>
      <PodcastsDoneScreen
        childName={childName}
        modelName={modelName}
        iosVersion={iosVersion}
        variant={variant}
        accessEndsAt={accessEndsAt}
        trialDaysRemaining={trialDaysRemaining}
        showSubscribe={showSubscribe}
        onManageSettings={() => navigate(`/children/${childId}/ios-devices/${deviceId}`)}
        onSubscribe={handleSubscribe}
        onMaybeLater={() => navigate(`/`)}
      />
    </ScreenShell>
  );
};

export default ClaimPodcastsDeviceDone;
