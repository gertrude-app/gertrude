import { ApiErrorMessage, Loading, PlanGateScreen, ScreenShell } from '@dash/components';
import React, { useEffect, useState } from 'react';
import { useNavigate, useParams, useSearchParams } from 'react-router-dom';
import type { SubscriptionPanelAction, SubscriptionTier } from '@dash/types';
import Current from '../../../environment';
import { Key, useMutation, useQuery } from '../../../hooks';
import { planGatePrimaryLabel } from '../../../lib/subscriptionActions';

const ClaimMusicDevicePayment: React.FC = () => {
  const { code = `` } = useParams<{ code: string }>();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const checkoutCancelled = searchParams.has(`session_id`);
  const [paymentError, setPaymentError] = useState<string | undefined>();

  const query = useQuery(Key.musicClaimData(code), () =>
    Current.api.getMusicClaimData({ code: parseInt(code, 10) }),
  );

  const startCheckout = useMutation(
    (tier: SubscriptionTier) =>
      Current.api.startCheckoutSession({
        tier,
        successPath: `/claim-music-device/${code}/claim`,
        cancelPath: `/claim-music-device/${code}/payment`,
      }),
    {
      onError: () => setPaymentError(`Failed to open Stripe. Please try again.`),
    },
  );

  const openBillingPortal = useMutation(
    (configuration: `lightTier` | `mediumTier` | `default`) =>
      Current.api.openBillingPortal({
        returnPath: `/claim-music-device/${code}/payment`,
        configuration,
      }),
    {
      onError: () => setPaymentError(`Failed to open Stripe. Please try again.`),
    },
  );

  const changeTier = useMutation(
    (to: SubscriptionTier) => Current.api.changeSubscriptionTier({ to }),
    {
      onSuccess: () => navigate(`/claim-music-device/${code}/claim`),
      onError: () => setPaymentError(`Failed to update your plan. Please try again.`),
    },
  );

  useEffect(() => {
    if (query.isSuccess && !query.data.paymentAction) {
      navigate(`/claim-music-device/${code}/claim`, { replace: true });
    }
  }, [query.isSuccess, query.data?.paymentAction, navigate, code]);

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

  if (query.isPending) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  const { modelName, iosVersion, paymentAction } = query.data;

  if (!paymentAction) {
    return <Loading />;
  }

  const deviceType = modelName.toLowerCase().includes(`ipad`) ? `iPad` : `iPhone`;

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
        changeTier.mutate(action.to);
        return;
      case `startFullTrial`:
        setPaymentError(`Please manage your subscription from Settings.`);
        return;
    }
  };

  return (
    <ScreenShell title={`Connect ${deviceType}`}>
      <PlanGateScreen
        icon="music"
        subtitle={`${modelName} · iOS ${iosVersion}`}
        message={
          <>
            Gertrude Music requires a <b>Gertrude Medium or Full subscription</b> before
            this {deviceType} can be connected.
          </>
        }
        plan="medium"
        extraBullets={[
          `Includes Gertrude Music for approved Apple Music artists and albums`,
        ]}
        priceSize="emphasized"
        checkoutCancelled={checkoutCancelled}
        error={paymentError}
        primaryLabel={planGatePrimaryLabel(paymentAction)}
        isWorking={
          startCheckout.isPending || openBillingPortal.isPending || changeTier.isPending
        }
        onPrimary={() => handlePaymentAction(paymentAction)}
        secondary={{ label: `Maybe later`, onClick: () => navigate(`/`) }}
      />
    </ScreenShell>
  );
};

export default ClaimMusicDevicePayment;
