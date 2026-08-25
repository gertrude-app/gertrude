import { EmptyState } from '@gertrude/ui';
import { createFileRoute } from '@tanstack/react-router';
import { CircleAlertIcon, RefreshCwIcon } from 'lucide-react';
import React from 'react';
import type { SubscriptionPanelAction } from '@shared/pairql/src/account';
import BillingSettingsPage from '#/components/pages/settings/BillingSettingsPage';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useMutation } from '#/pairql/mutation';
import { useQuery } from '#/pairql/query';

const BillingSettingsRoute: React.FC = () => {
  const query = useQuery(Key.accountBilling, () => liveClient.getAccountBilling());
  const [pendingAction, setPendingAction] = React.useState<
    SubscriptionPanelAction | undefined
  >();
  const startCheckout = useMutation(liveClient.startAccountCheckout, {
    toast: {
      loading: `Opening secure checkout…`,
      success: `Checkout ready`,
      error: `Couldn't open checkout`,
    },
  });
  const openPortal = useMutation(liveClient.openAccountBillingPortal, {
    toast: {
      loading: `Opening billing portal…`,
      success: `Billing portal ready`,
      error: `Couldn't open the billing portal`,
    },
  });
  const changeTier = useMutation(liveClient.changeAccountSubscriptionTier, {
    invalidating: [Key.accountBilling],
    toast: {
      loading: `Updating plan…`,
      success: `Plan updated`,
      error: `Couldn't update your plan`,
    },
  });
  const startTrial = useMutation(liveClient.startAccountFullTrial, {
    invalidating: [Key.accountBilling],
    toast: {
      loading: `Starting trial…`,
      success: `Full trial started`,
      error: `Couldn't start the trial`,
    },
  });

  if (query.data === undefined && query.isError) {
    return (
      <EmptyState
        icon={CircleAlertIcon}
        title="Couldn't load billing"
        description={query.error.userMessage ?? `Check your connection and try again.`}
        button={{
          text: `Try again`,
          type: `button`,
          onClick: () => void query.refetch(),
          icon: RefreshCwIcon,
        }}
        className="mt-4 bg-white"
      />
    );
  }

  if (!query.data) {
    return null;
  }

  const handleAction = async (action: SubscriptionPanelAction): Promise<void> => {
    setPendingAction(action);
    try {
      switch (action.case) {
        case `startCheckout`:
        case `reactivateViaCheckout`: {
          const output = await startCheckout.mutateAsync({
            tier: action.tier,
            successPath: `/settings/billing/checkout-success`,
            cancelPath: `/settings/billing/checkout-cancel`,
          });
          window.location.assign(output.url);
          return;
        }
        case `openBillingPortal`: {
          const output = await openPortal.mutateAsync({
            returnPath: `/settings/billing`,
            configuration: action.config,
          });
          window.location.assign(output.url);
          return;
        }
        case `changeSubscriptionTier`:
          await changeTier.mutateAsync({ tier: action.to });
          return;
        case `startFullTrial`:
          await startTrial.mutateAsync(undefined);
          return;
      }
    } catch {
      return;
    } finally {
      setPendingAction(undefined);
    }
  };

  return (
    <BillingSettingsPage
      billing={query.data}
      pendingAction={pendingAction}
      onAction={handleAction}
    />
  );
};

export const Route = createFileRoute(`/_app/settings/billing/`)({
  component: BillingSettingsRoute,
});
