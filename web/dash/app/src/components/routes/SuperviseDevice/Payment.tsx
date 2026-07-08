import { ApiErrorMessage, Loading, PlanGateScreen, ScreenShell } from '@dash/components';
import { posessive } from '@shared/string';
import React, { useEffect, useState } from 'react';
import { useNavigate, useParams, useSearchParams } from 'react-router-dom';
import type { SubscriptionPanelAction, SubscriptionTier } from '@dash/types';
import Current from '../../../environment';
import { Key, useMutation, useQuery } from '../../../hooks';
import { planGatePrimaryLabel } from '../../../lib/subscriptionActions';

const SuperviseDevicePayment: React.FC = () => {
  const { code = `` } = useParams<{ code: string }>();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const checkoutCancelled = searchParams.has(`session_id`);
  const [paymentError, setPaymentError] = useState<string | undefined>();

  const deviceStatus = useQuery(Key.supervisionDeviceStatus(code), () =>
    Current.api.getIOSDeviceSupervisionStatus({ code: parseInt(code ?? `0`, 10) }),
  );

  const startCheckout = useMutation(
    (tier: SubscriptionTier) =>
      Current.api.startCheckoutSession({
        tier,
        successPath: `/supervise-device/${code}/download-helper`,
        cancelPath: `/supervise-device/${code}/payment`,
        associatedIosDeviceId: deviceStatus.data?.deviceId,
      }),
    {
      onError: () => setPaymentError(`Failed to open Stripe. Please try again.`),
    },
  );

  const openBillingPortal = useMutation(
    (configuration: `lightTier` | `mediumTier` | `default`) =>
      Current.api.openBillingPortal({
        returnPath: `/supervise-device/${code}/payment`,
        configuration,
      }),
    {
      onError: () => setPaymentError(`Failed to open Stripe. Please try again.`),
    },
  );

  useEffect(() => {
    if (deviceStatus.isSuccess && !deviceStatus.data.requiresPayment) {
      navigate(`/supervise-device/${code}/download-helper`, { replace: true });
    }
  }, [deviceStatus.isSuccess, deviceStatus.data?.requiresPayment, navigate, code]);

  useEffect(() => {
    if (startCheckout.isSuccess) {
      window.location.href = startCheckout.data.url;
    }
  }, [startCheckout.isSuccess, startCheckout.data?.url]);

  useEffect(() => {
    if (openBillingPortal.isSuccess) {
      window.location.href = openBillingPortal.data.url;
    }
  }, [openBillingPortal.isSuccess, openBillingPortal.data?.url]);

  if (deviceStatus.isPending) {
    return <Loading />;
  }

  if (deviceStatus.isError) {
    return <ApiErrorMessage error={deviceStatus.error} />;
  }

  if (!deviceStatus.data.requiresPayment) {
    return <Loading />;
  }

  const { childName, modelName, deviceType, iosVersion, paymentAction } =
    deviceStatus.data;

  if (!paymentAction) {
    return <ApiErrorMessage />;
  }

  const handlePaymentAction = (action: SubscriptionPanelAction): void => {
    setPaymentError(undefined);
    switch (action.case) {
      case `startCheckout`:
      case `reactivateViaCheckout`:
        startCheckout.mutate(action.tier);
        return;
      case `openBillingPortal`:
        openBillingPortal.mutate(action.config);
        return;
      case `changeSubscriptionTier`:
      case `startFullTrial`:
        setPaymentError(`Please manage your subscription from Settings.`);
        return;
    }
  };

  return (
    <ScreenShell title={`Continue ${deviceType} Setup`}>
      <PlanGateScreen
        icon="credit-card"
        subtitle={`Setting up ${posessive(childName)} ${modelName} · iOS ${iosVersion}`}
        message={
          <>
            To supervise and manage {posessive(childName)} {deviceType}, you’ll need a
            {` `}
            <b>Gertrude subscription.</b>
          </>
        }
        extraBullets={[`All basic iOS blocking (GIFs, Apple Maps, Spotify etc.)`]}
        onPrimary={() => handlePaymentAction(paymentAction)}
        primaryLabel={planGatePrimaryLabel(paymentAction)}
        isWorking={startCheckout.isPending || openBillingPortal.isPending}
        checkoutCancelled={checkoutCancelled}
        error={paymentError}
      />
    </ScreenShell>
  );
};

export default SuperviseDevicePayment;
