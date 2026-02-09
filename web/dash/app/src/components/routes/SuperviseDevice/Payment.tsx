import { ApiErrorMessage, Loading } from '@dash/components';
import React, { useEffect } from 'react';
import { useNavigate, useParams, useSearchParams } from 'react-router-dom';
import Current from '../../../environment';
import { Key, useMutation, useQuery } from '../../../hooks';
import { PaymentGateScreen, ScreenShell } from './screens';

const SuperviseDevicePayment: React.FC = () => {
  const { code = `` } = useParams<{ code: string }>();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const checkoutCancelled = searchParams.has(`session_id`);

  const deviceStatus = useQuery(Key.supervisionDeviceStatus(code), () =>
    Current.api.getSupervisionDeviceStatus({ code: parseInt(code ?? `0`, 10) }),
  );

  const getStripeUrl = useMutation(() =>
    Current.api.stripeUrl({
      successPath: `/supervise-device/${code}/download-helper`,
      cancelPath: `/supervise-device/${code}/payment`,
      tier: `light`,
    }),
  );

  useEffect(() => {
    if (deviceStatus.isSuccess && !deviceStatus.data.requiresPayment) {
      navigate(`/supervise-device/${code}/download-helper`, { replace: true });
    }
  }, [deviceStatus.isSuccess, deviceStatus.data?.requiresPayment, navigate, code]);

  useEffect(() => {
    if (getStripeUrl.isSuccess) {
      window.location.href = getStripeUrl.data.url;
    }
  }, [getStripeUrl.isSuccess, getStripeUrl.data?.url]);

  if (deviceStatus.isPending) {
    return <Loading />;
  }

  if (deviceStatus.isError) {
    return <ApiErrorMessage error={deviceStatus.error} />;
  }

  if (!deviceStatus.data.requiresPayment) {
    return <Loading />;
  }

  const { childName, modelName, deviceType, iosVersion } = deviceStatus.data;

  return (
    <ScreenShell title={`Continue ${deviceType} Setup`}>
      <PaymentGateScreen
        childName={childName}
        modelName={modelName}
        iosVersion={iosVersion}
        deviceType={deviceType}
        onSubscribe={() => getStripeUrl.mutate(undefined)}
        isRedirecting={getStripeUrl.isPending}
        checkoutCancelled={checkoutCancelled}
      />
    </ScreenShell>
  );
};

export default SuperviseDevicePayment;
