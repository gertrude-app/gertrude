import { AmDoneScreen, ScreenShell } from '@dash/components';
import React from 'react';
import { Navigate, useLocation, useNavigate, useParams } from 'react-router-dom';
import type { T } from '@shared/pairql/dashboard';
import { amDoneVariant } from './amDoneVariant';

export interface AmDoneNavState {
  subscription: T.ClaimAmDevice.Output[`subscription`];
  childName: string;
  modelName: string;
  iosVersion: string;
}

const ClaimAmDeviceDone: React.FC = () => {
  const { code = `` } = useParams<{ code: string }>();
  const navigate = useNavigate();
  const location = useLocation();
  const state = location.state as AmDoneNavState | null;

  // reached without nav state (e.g. refresh / direct link) — bounce back through
  // claim, which re-fetches and re-routes here with the carried subscription state
  if (!state) {
    return <Navigate to={`/claim-am-device/${code}/claim`} replace />;
  }

  const { subscription, childName, modelName, iosVersion } = state;
  const deviceType = modelName.toLowerCase().includes(`ipad`) ? `iPad` : `iPhone`;
  const { variant, accessEndsAt, trialDaysRemaining, subscribeUrl } =
    amDoneVariant(subscription);

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
      <AmDoneScreen
        childName={childName}
        modelName={modelName}
        iosVersion={iosVersion}
        variant={variant}
        accessEndsAt={accessEndsAt}
        trialDaysRemaining={trialDaysRemaining}
        onBackToDashboard={() => navigate(`/`)}
        onSubscribe={handleSubscribe}
        onMaybeLater={() => navigate(`/`)}
      />
    </ScreenShell>
  );
};

export default ClaimAmDeviceDone;
