import React from 'react';
import { useSearchParams } from 'react-router-dom';
import { FullscreenModalForm } from '@dash/components';
import { useFireAndForget } from '../../hooks';
import Current from '../../environment';

const CheckoutCancel: React.FC = () => {
  const [params] = useSearchParams();
  const sessionId = params.get(`session_id`) ?? ``;

  useFireAndForget(() =>
    Current.api.handleCheckoutCancel({ stripeCheckoutSessionId: sessionId }),
  );

  return (
    <FullscreenModalForm
      request="failed"
      error="Checkout process cancelled. Please contact support if this was not your intention, or if you are having any kind of trouble signing up."
    />
  );
};

export default CheckoutCancel;
