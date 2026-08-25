import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import CheckoutResultPage from '#/components/pages/settings/CheckoutResultPage';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useMutation } from '#/pairql/mutation';

const CheckoutSuccessRoute: React.FC = () => {
  const { session_id: sessionId } = Route.useSearch();
  const started = React.useRef(false);
  const mutation = useMutation(liveClient.handleAccountCheckoutSuccess, {
    invalidating: [Key.accountBilling],
  });

  React.useEffect(() => {
    if (started.current || !sessionId) {
      return;
    }

    started.current = true;
    mutation.mutate({ stripeCheckoutSessionId: sessionId });
  }, [mutation, sessionId]);

  if (!sessionId) {
    return (
      <CheckoutResultPage status="error" message="The checkout session is missing." />
    );
  }

  if (mutation.isError) {
    return (
      <CheckoutResultPage
        status="error"
        message={mutation.error.userMessage ?? `Check your connection and try again.`}
      />
    );
  }

  return <CheckoutResultPage status={mutation.isSuccess ? `success` : `loading`} />;
};

export const Route = createFileRoute(`/_app/settings/billing/checkout-success`)({
  validateSearch: (search): { session_id?: string } => ({
    session_id:
      typeof search[`session_id`] === `string` ? search[`session_id`] : undefined,
  }),
  component: CheckoutSuccessRoute,
});
