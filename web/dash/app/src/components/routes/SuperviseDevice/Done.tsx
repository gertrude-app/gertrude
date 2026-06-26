import { ApiErrorMessage, Loading, ScreenShell } from '@dash/components';
import React from 'react';
import { useParams } from 'react-router-dom';
import Current from '../../../environment';
import { Key, useQuery } from '../../../hooks';
import { DoneScreen } from './screens';

const SuperviseDeviceDone: React.FC = () => {
  const { code = `` } = useParams<{ code: string }>();

  const query = useQuery(Key.supervisionDeviceStatus(code), () =>
    Current.api.getIOSDeviceSupervisionStatus({ code: parseInt(code, 10) }),
  );

  if (query.isPending) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  const { deviceId, childId, childName, modelName, deviceType, iosVersion } = query.data;

  return (
    <ScreenShell title={`${deviceType} Setup Complete`}>
      <DoneScreen
        childName={childName}
        modelName={modelName}
        iosVersion={iosVersion}
        deviceId={deviceId}
        childId={childId}
      />
    </ScreenShell>
  );
};

export default SuperviseDeviceDone;
