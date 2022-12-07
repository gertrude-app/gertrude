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
  const verifiedAdminId = Req.payload(verifyReq);
  const paymentUrlReq = useSelector((state) => state.signup.createPaymentUrlReq);
  const paymentUrlReqState = paymentUrlReq.state;

  useEffect(() => {
    if (paymentUrlReqState === `idle` && verifiedAdminId) {
      dispatch(createSignupPaymentUrl(verifiedAdminId));
    }
  }, [dispatch, verifiedAdminId, paymentUrlReqState]);

  useEffect(() => {
    if (verifyReq?.state === `idle`) {
      dispatch(verifySignupEmail(token));
    }
  }, [dispatch, token, verifyReq?.state]);

  if (verifyReq.state === `failed`) {
    return <FullscreenModalForm request="failed" error="Failed to verify your email." />;
  }

  if (paymentUrlReq.state === `failed`) {
    return (
      <FullscreenModalForm request="failed" error="Unexpected error, please try again." />
    );
  }

  if (verifyReq.state === `idle` || verifyReq.state === `ongoing`) {
    return <FullscreenModalForm request="ongoing" text="Verifying your email..." />;
  }

  if (paymentUrlReq.state === `idle` || paymentUrlReq.state === `ongoing`) {
    return <FullscreenModalForm request="ongoing" />;
  }

  window.location.href = paymentUrlReq.payload;
  return <FullscreenModalForm request="ongoing" text="Redirecting to trial setup..." />;
};

export default VerifySignupEmail;
