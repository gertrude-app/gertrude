import { MusicDoneScreen, ScreenShell } from '@dash/components';
import React from 'react';
import { Navigate, useLocation, useNavigate, useParams } from 'react-router-dom';

export interface MusicDoneNavState {
  childName: string;
  modelName: string;
  iosVersion: string;
}

const ClaimMusicDeviceDone: React.FC = () => {
  const { code = `` } = useParams<{ code: string }>();
  const navigate = useNavigate();
  const location = useLocation();
  const state = location.state as MusicDoneNavState | null;

  if (!state) {
    return <Navigate to={`/claim-music-device/${code}/claim`} replace />;
  }

  const { childName, modelName, iosVersion } = state;
  const deviceType = modelName.toLowerCase().includes(`ipad`) ? `iPad` : `iPhone`;

  return (
    <ScreenShell title={`${deviceType} Connected`}>
      <MusicDoneScreen
        childName={childName}
        modelName={modelName}
        iosVersion={iosVersion}
        onDone={() => navigate(`/`)}
      />
    </ScreenShell>
  );
};

export default ClaimMusicDeviceDone;
