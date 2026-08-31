import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import CheckoutResultPage from '#/components/pages/settings/CheckoutResultPage';
import { liveClient } from '#/pairql/client';
import { useMutation } from '#/pairql/mutation';

const CheckoutCancelRoute: React.FC = () => {
  const { session_id: sessionId } = Route.useSearch();
  const started = React.useRef(false);
  const mutation = useMutation(liveClient.handleAccountCheckoutCancel);

  React.useEffect(() => {
    if (started.current || !sessionId) {
      return;
    }

    started.current = true;
    mutation.mutate({ stripeCheckoutSessionId: sessionId });
  }, [mutation, sessionId]);

  return <CheckoutResultPage status="canceled" />;
};

export const Route = createFileRoute(`/_app/settings/billing/checkout-cancel`)({
  validateSearch: (search): { session_id?: string } => ({
    session_id:
      typeof search[`session_id`] === `string` ? search[`session_id`] : undefined,
  }),
  component: CheckoutCancelRoute,
});
