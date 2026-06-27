import { ApiErrorMessage, Loading } from '@dash/components';
import { Result } from '@shared/pairql';
import React from 'react';
import { Navigate, Outlet, useParams, useSearchParams } from 'react-router-dom';
import Current from '../../../environment';
import { Key, useFireAndForget, useQuery } from '../../../hooks';

const RequirePaidSupervision: React.FC = () => {
  const { code = `` } = useParams<{ code: string }>();
  const [searchParams] = useSearchParams();
  const sessionId = searchParams.get(`session_id`);

  const checkoutQuery = useFireAndForget(
    () => {
      if (!sessionId) return Result.resolveUnexpected(`b8a1c0f2`);
      return Current.api.handleCheckoutSuccess({ stripeCheckoutSessionId: sessionId });
    },
    { when: !!sessionId },
  );

  const query = useQuery(
    Key.supervisionDeviceStatus(code),
    () => Current.api.getIOSDeviceSupervisionStatus({ code: parseInt(code ?? `0`, 10) }),
    { enabled: !sessionId || checkoutQuery.isSuccess },
  );

  if (sessionId && checkoutQuery.isPending) {
    return <Loading />;
  }

  if (checkoutQuery.isError) {
    return <ApiErrorMessage error={checkoutQuery.error} />;
  }

  if (query.isPending) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  const alreadySupervised = query.data.supervisionStatus === `supervised`;
  if (query.data.requiresPayment && !alreadySupervised) {
    return <Navigate to={`/supervise-device/${code}/payment`} replace />;
  }

  return <Outlet />;
};

export default RequirePaidSupervision;
