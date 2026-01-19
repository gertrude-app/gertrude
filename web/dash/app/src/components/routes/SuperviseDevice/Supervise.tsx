import { ApiErrorMessage, Loading, PageHeading } from '@dash/components';
import React from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import Current from '../../../environment';
import { Key, useQuery } from '../../../hooks';
import { SuperviseScreen } from './screens';

const SuperviseDeviceSupervise: React.FC = () => {
  const { code = `` } = useParams<{ code: string }>();
  const navigate = useNavigate();

  const query = useQuery(Key.supervisionDeviceStatus(code), () =>
    Current.api.getSupervisionDeviceStatus({ code: parseInt(code, 10) }),
  );

  if (query.isPending) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  const { childName, modelName, deviceType, iosVersion } = query.data;
  const codeNum = parseInt(code, 10);

  const handleDone = (): void => {
    navigate(`/supervise-device/${code}/done`);
  };

  return (
    <div className="relative max-w-3xl">
      <PageHeading icon="phone">Continue {deviceType} Setup</PageHeading>
      <div className="mt-8 bg-white rounded-2xl border border-slate-200 p-6">
        <SuperviseScreen
          childName={childName}
          modelName={modelName}
          iosVersion={iosVersion}
          code={codeNum}
          onDone={handleDone}
        />
      </div>
    </div>
  );
};

export default SuperviseDeviceSupervise;
