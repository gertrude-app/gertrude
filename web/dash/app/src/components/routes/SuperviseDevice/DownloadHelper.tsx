import { ApiErrorMessage, Loading, PageHeading } from '@dash/components';
import React from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import Current from '../../../environment';
import { Key, useQuery } from '../../../hooks';
import { DownloadHelperScreen } from './screens';

const SuperviseDeviceDownloadHelper: React.FC = () => {
  const { code = `` } = useParams<{ code: string }>();
  const navigate = useNavigate();

  const query = useQuery(Key.supervisionDeviceStatus(code), () =>
    Current.api.getSupervisionDeviceStatus({ code: parseInt(code ?? `0`, 10) }),
  );

  if (query.isPending) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  const { childName, modelName, deviceType, iosVersion } = query.data;

  const handleDownload = (platform: `mac` | `windows`): void => {
    const url = `${Current.env.apiEndpoint()}/download-supervision-app/${code}/platform/${platform}`;
    const iframe = document.createElement(`iframe`);
    iframe.style.display = `none`;
    iframe.src = url;
    document.body.appendChild(iframe);
    setTimeout(() => iframe.remove(), 5000);
  };

  const handleNext = (): void => {
    navigate(`/supervise-device/${code}/supervise`);
  };

  return (
    <div className="relative max-w-3xl">
      <PageHeading icon="phone">Continue {deviceType} Setup</PageHeading>
      <div className="mt-8 bg-white rounded-2xl border border-slate-200 p-6">
        <DownloadHelperScreen
          childName={childName}
          modelName={modelName}
          iosVersion={iosVersion}
          onDownload={handleDownload}
          onNext={handleNext}
        />
      </div>
    </div>
  );
};

export default SuperviseDeviceDownloadHelper;
