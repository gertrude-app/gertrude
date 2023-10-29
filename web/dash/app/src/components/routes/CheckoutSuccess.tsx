import React from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';
import { RequestModal } from '@dash/components';
import { Result } from '@dash/types';
import { useFireAndForget } from '../../hooks';
import Current from '../../environment';
import ReqState from '../../lib/ReqState';

const CheckoutSuccess: React.FC = () => {
  const [params] = useSearchParams();
  const navigate = useNavigate();
  const sessionId = params.get(`session_id`);

  const query = useFireAndForget(() => {
    if (!sessionId) return Result.resolveUnexpected(`4c61dc17`);
    return Current.api.handleCheckoutSuccess({ stripeCheckoutSessionId: sessionId });
  });

  const request = ReqState.fromQuery(query);

  return (
    <RequestModal
      request={request}
      successTitle="Payment setup complete"
      primaryButton={{
        label: `Back to settings →`,
        action: () => navigate(`/settings`),
      }}
      withPayload={() =>
        `Thanks for using Gertrude! You can manage or cancel your subscription at any time from the Settings screen.`
      }
      onDismiss={() => navigate(`/settings`)}
    />
  );
};

export default CheckoutSuccess;
