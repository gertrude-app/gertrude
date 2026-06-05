import { ApiErrorMessage, Loading, ScreenShell } from '@dash/components';
import { Result } from '@shared/pairql';
import React from 'react';
import { useNavigate, useParams, useSearchParams } from 'react-router-dom';
import Current from '../../../environment';
import { Key, useFireAndForget, useQuery } from '../../../hooks';
import { DownloadHelperScreen } from './screens';

const SuperviseDeviceDownloadHelper: React.FC = () => {
  const { code = `` } = useParams<{ code: string }>();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const sessionId = searchParams.get(`session_id`);

  useFireAndForget(
    () => {
      if (!sessionId) return Result.resolveUnexpected(`a7f2c301`);
      return Current.api.handleCheckoutSuccess({ stripeCheckoutSessionId: sessionId });
    },
    { when: !!sessionId },
  );

  const query = useQuery(Key.supervisionDeviceStatus(code), () =>
    Current.api.getIOSDeviceSupervisionStatus({ code: parseInt(code ?? `0`, 10) }),
  );

  if (query.isPending) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  const { childName, modelName, deviceType, iosVersion, requiresPayment } = query.data;

  const handleDownload = (platform: `mac` | `windows`): void => {
    if (requiresPayment) {
      navigate(`/supervise-device/${code}/payment`, { replace: true });
      return;
    }
    const url = `${Current.env.apiEndpoint()}/download-supervision-app/${code}/platform/${platform}`;
    const iframe = document.createElement(`iframe`);
    iframe.style.display = `none`;
    iframe.src = url;
    document.body.appendChild(iframe);
    setTimeout(() => iframe.remove(), 5000);
  };

  const handleNext = (): void => {
    navigate(`/supervise-device/${code}/launch-helper`);
  };

  return (
    <ScreenShell title={`Continue ${deviceType} Setup`}>
      <DownloadHelperScreen
        childName={childName}
        modelName={modelName}
        iosVersion={iosVersion}
        onDownload={handleDownload}
        onNext={handleNext}
      />
    </ScreenShell>
  );
};

export default SuperviseDeviceDownloadHelper;
