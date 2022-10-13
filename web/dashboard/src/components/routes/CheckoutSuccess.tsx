import React, { useEffect } from 'react';
import { useSearchParams, Navigate } from 'react-router-dom';
import FullscreenModalForm from '@dashboard/Unauthed/FullscreenModalForm';
import { useDispatch, useSelector } from '../../redux/hooks';
import { handleSignupPaymentSuccess } from '../../redux/slice-signup';

const CheckoutSuccess: React.FC = () => {
  const [params] = useSearchParams();
  const dispatch = useDispatch();
  const req = useSelector((state) => state.signup.checkoutSuccessReq);
  const reqState = req.state;
  const sessionId = params.get(`session_id`);

  useEffect(() => {
    if (reqState === `idle` && sessionId) {
      dispatch(handleSignupPaymentSuccess(sessionId));
    }
  }, [dispatch, sessionId, reqState]);

  if (req.state === `ongoing` || req.state === `idle`) {
    return <FullscreenModalForm request="ongoing" text="Completing signup..." />;
  }

  if (!sessionId) {
    return (
      <FullscreenModalForm
        request="failed"
        error="Error completing signup: missing checkout session id."
      />
    );
  }

  if (req.state === `failed`) {
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
