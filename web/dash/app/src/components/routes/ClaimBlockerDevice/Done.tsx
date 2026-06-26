import { BlockerDoneScreen, ScreenShell } from '@dash/components';
import React from 'react';
import { Navigate, useLocation, useNavigate, useParams } from 'react-router-dom';

export interface BlockerDoneNavState {
  childName: string;
  childId: string;
  deviceId: string;
  modelName: string;
  iosVersion: string;
}

const ClaimBlockerDeviceDone: React.FC = () => {
  const { code = `` } = useParams<{ code: string }>();
  const navigate = useNavigate();
  const location = useLocation();
  const state = location.state as BlockerDoneNavState | null;

  if (!state) {
    return <Navigate to={`/claim-blocker-device/${code}/claim`} replace />;
  }

  const { childName, childId, deviceId, modelName, iosVersion } = state;
  const deviceType = modelName.toLowerCase().includes(`ipad`) ? `iPad` : `iPhone`;

  return (
    <ScreenShell title={`${deviceType} Connected`}>
      <BlockerDoneScreen
        childName={childName}
        modelName={modelName}
        iosVersion={iosVersion}
        onManageSettings={() => navigate(`/children/${childId}/ios-devices/${deviceId}`)}
      />
    </ScreenShell>
  );
};

export default ClaimBlockerDeviceDone;
