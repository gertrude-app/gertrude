import React, { useEffect } from 'react';
import { FullscreenModalForm } from '@dash/components';
import { useParams } from 'react-router-dom';
import { useDispatch, useSelector } from '../../redux/hooks';
import { verifySignupEmail, createSignupPaymentUrl } from '../../redux/slice-signup';
import { Req } from '../../redux/helpers';

const VerifySignupEmail: React.FC = () => {
  const { token = `` } = useParams<{ token: UUID }>();
  const dispatch = useDispatch();
  const verifyReq = useSelector((state) => state.signup.verifyEmailReq);
  const verifyReqState = verifyReq.state;
  const verifiedAdminId = Req.payload(verifyReq);
  const paymentUrlReq = useSelector((state) => state.signup.createPaymentUrlReq);
  const paymentUrlReqState = paymentUrlReq.state;

  useEffect(() => {
    if (paymentUrlReqState === `idle` && verifiedAdminId) {
      dispatch(createSignupPaymentUrl(verifiedAdminId));
    }
  }, [dispatch, verifiedAdminId, paymentUrlReqState]);

  useEffect(() => {
    if (verifyReqState === `idle`) {
      dispatch(verifySignupEmail(token));
    }
  }, [dispatch, token, verifyReqState]);

  if (verifyReq.state === `idle` || verifyReq.state === `ongoing`) {
    return <FullscreenModalForm request="ongoing" text="Verifying your email..." />;
  }

  if (paymentUrlReq.state === `idle` || paymentUrlReq.state === `ongoing`) {
    return <FullscreenModalForm request="ongoing" text="Preparing for checkout..." />;
  }

  if (verifyReq.state === `failed`) {
    return <FullscreenModalForm request="failed" error="Failed to verify your email." />;
  }

  if (paymentUrlReq.state === `failed`) {
    return (
      <FullscreenModalForm
        request="failed"
        error="Failed to create checkout session, please try again."
      />
    );
  }

  window.location.href = paymentUrlReq.payload;
  return <FullscreenModalForm request="ongoing" text="Redirecting to checkout..." />;
};

export default VerifySignupEmail;
