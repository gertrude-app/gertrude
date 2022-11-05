import React, { useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';
import { FullscreenModalForm } from '@dash/components';
import { useDispatch } from '../../redux/hooks';
import { handleSignupPaymentCanceled } from '../../redux/slice-signup';

const CheckoutCancel: React.FC = () => {
  const [params] = useSearchParams();
  const dispatch = useDispatch();
  const sessionId = params.get(`session_id`);

  useEffect(() => {
    dispatch(handleSignupPaymentCanceled(sessionId ?? ``));
  }, [dispatch, sessionId]);

  return (
    <FullscreenModalForm
      request="failed"
      error="Checkout process cancelled. Please contact support if this was not your intention, or if you are having any kind of trouble signing up."
    />
  );
};

export default CheckoutCancel;
