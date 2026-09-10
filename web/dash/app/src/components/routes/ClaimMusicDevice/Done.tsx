import { MusicDoneScreen, ScreenShell } from '@dash/components';
import React, { useState } from 'react';
import { Navigate, useLocation, useNavigate, useParams } from 'react-router-dom';
import type { T } from '@shared/pairql/dashboard';
import Current from '../../../environment';
import { Key, useQuery } from '../../../hooks';

export interface MusicDoneNavState {
  childName: string;
  childId: string;
  deviceId: string;
  modelName: string;
  iosVersion: string;
  subscription?: T.ClaimMusicDevice.Output[`subscription`];
}

const ClaimMusicDeviceDone: React.FC = () => {
  const { code = `` } = useParams<{ code: string }>();
  const navigate = useNavigate();
  const location = useLocation();
  const state = location.state as MusicDoneNavState | null;
  const [shouldPoll, setShouldPoll] = useState(state?.subscription === undefined);
  const query = useQuery(
    Key.musicClaimData(code),
    () => Current.api.getMusicClaimData({ code: parseInt(code, 10) }),
    {
      enabled: state !== null,
      onReceive: (data) => {
        if (data.resumeStep?.subscription !== undefined) setShouldPoll(false);
      },
      refetchIntervalSeconds: shouldPoll ? 3 : undefined,
    },
  );

  if (!state) {
    return <Navigate to={`/claim-music-device/${code}/claim`} replace />;
  }

  const { childName, childId, deviceId, modelName, iosVersion } = state;
  const deviceType = modelName.toLowerCase().includes(`ipad`) ? `iPad` : `iPhone`;
  const subscription = query.data?.resumeStep?.subscription ?? state.subscription;

  return (
    <ScreenShell title={`${deviceType} Connected`}>
      <MusicDoneScreen
        childName={childName}
        modelName={modelName}
        iosVersion={iosVersion}
        subscription={subscription}
        onManageSettings={() => navigate(`/children/${childId}/ios-devices/${deviceId}`)}
      />
    </ScreenShell>
  );
};

export default ClaimMusicDeviceDone;
