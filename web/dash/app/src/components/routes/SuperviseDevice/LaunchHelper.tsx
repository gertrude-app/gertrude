import { ApiErrorMessage, Loading, ScreenShell } from '@dash/components';
import React from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import Current from '../../../environment';
import { Key, useQuery } from '../../../hooks';
import { LaunchHelperScreen } from './screens';

const SuperviseDeviceLaunchHelper: React.FC = () => {
  const { code = `` } = useParams<{ code: string }>();
  const navigate = useNavigate();

  const query = useQuery(Key.supervisionDeviceStatus(code), () =>
    Current.api.getIOSDeviceSupervisionStatus({ code: parseInt(code, 10) }),
  );

  if (query.isPending) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  const { childName, modelName, deviceType, iosVersion } = query.data;

  const handleNext = (): void => {
    navigate(`/supervise-device/${code}/supervise`);
  };

  return (
    <ScreenShell title={`Continue ${deviceType} Setup`}>
      <LaunchHelperScreen
        childName={childName}
        modelName={modelName}
        iosVersion={iosVersion}
        onNext={handleNext}
      />
    </ScreenShell>
  );
};

export default SuperviseDeviceLaunchHelper;
