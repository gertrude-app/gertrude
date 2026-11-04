import { toast } from '@gertrude/ui';
import { createFileRoute, redirect } from '@tanstack/react-router';
import React from 'react';
import CheckoutResultPage from '#/components/pages/settings/CheckoutResultPage';
import { pairingReturnPath } from '#/lib/authRedirect';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';

const CheckoutSuccessRoute: React.FC = () => {
  const { error } = Route.useLoaderData();
  return <CheckoutResultPage status="error" message={error} />;
};

export const Route = createFileRoute(`/_app/settings/billing/checkout-success`)({
  validateSearch: (search): { session_id?: string } => ({
    session_id:
      typeof search[`session_id`] === `string` ? search[`session_id`] : undefined,
  }),
  loaderDeps: ({ search }) => ({ sessionId: search.session_id }),
  loader: async ({ deps: { sessionId }, context }) => {
    if (!sessionId) {
      return { error: `The checkout session is missing.` };
    }

    const result = await liveClient.handleAccountCheckoutSuccess({
      stripeCheckoutSessionId: sessionId,
    });
    if (result.error) {
      return {
        error: result.error.userMessage ?? `Check your connection and try again.`,
      };
    }

    await context.queryClient.invalidateQueries({
      queryKey: Key.accountBilling.segments,
    });
    toast.success(`Your Gertrude subscription is ready`);
    throw redirect({
      to: (pairingReturnPath() ?? `/settings/billing`) as `/settings/billing`,
      replace: true,
    });
  },
  pendingComponent: () => <CheckoutResultPage status="loading" />,
  component: CheckoutSuccessRoute,
});
