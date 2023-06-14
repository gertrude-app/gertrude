import React from 'react';
import { useSearchParams, Navigate } from 'react-router-dom';
import { FullscreenModalForm } from '@dash/components';
import { Result } from '@dash/types';
import { useAuth, useFireAndForget } from '../../hooks';
import Current from '../../environment';

const CheckoutSuccess: React.FC = () => {
  const { login } = useAuth();
  const [params] = useSearchParams();
  const sessionId = params.get(`session_id`);

  const query = useFireAndForget(
    () => {
      if (!sessionId) return Result.resolveUnexpected(`4c61dc17`);
      return Current.api.handleCheckoutSuccess({ stripeCheckoutSessionId: sessionId });
    },
    { onReceive: ({ adminId, token }) => login(adminId, token) },
  );

  if (query.isLoading) {
    return <FullscreenModalForm request="ongoing" text="Completing signup..." />;
  }

  if (query.isError && !sessionId) {
    return (
      <FullscreenModalForm
        request="failed"
        error="Error completing signup: missing checkout session id."
      />
    );
  }

  if (query.isError) {
    return (
      <FullscreenModalForm
        request="failed"
        error="Error completing signup. Please try again, or contact support for more help."
      />
    );
  }

  return <Navigate to="/" replace />;
};

export default CheckoutSuccess;
