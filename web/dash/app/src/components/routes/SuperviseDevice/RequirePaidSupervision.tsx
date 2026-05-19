import { ApiErrorMessage, Loading } from '@dash/components';
import React from 'react';
import { Navigate, Outlet, useParams } from 'react-router-dom';
import Current from '../../../environment';
import { Key, useQuery } from '../../../hooks';

const RequirePaidSupervision: React.FC = () => {
  const { code = `` } = useParams<{ code: string }>();

  const query = useQuery(Key.supervisionDeviceStatus(code), () =>
    Current.api.getIOSDeviceSupervisionStatus({ code: parseInt(code ?? `0`, 10) }),
  );

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
