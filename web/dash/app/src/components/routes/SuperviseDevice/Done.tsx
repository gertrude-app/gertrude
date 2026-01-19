import { ApiErrorMessage, Loading, PageHeading } from '@dash/components';
import React from 'react';
import { useParams } from 'react-router-dom';
import Current from '../../../environment';
import { Key, useQuery } from '../../../hooks';
import { DoneScreen } from './screens';

const SuperviseDeviceDone: React.FC = () => {
  const { code = `` } = useParams<{ code: string }>();

  const query = useQuery(Key.supervisionDeviceStatus(code), () =>
    Current.api.getSupervisionDeviceStatus({ code: parseInt(code, 10) }),
  );

  if (query.isPending) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  const { deviceId, childName, modelName, deviceType, iosVersion } = query.data;

  return (
    <div className="relative max-w-3xl">
      <PageHeading icon="phone">{deviceType} Setup Complete</PageHeading>
      <div className="mt-8 bg-white rounded-2xl border border-slate-200 p-6">
        <DoneScreen
          childName={childName}
          modelName={modelName}
          iosVersion={iosVersion}
          deviceId={deviceId}
        />
      </div>
    </div>
  );
};

export default SuperviseDeviceDone;
