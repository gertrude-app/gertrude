import { ApiErrorMessage, Loading } from '@dash/components';
import React from 'react';
import { Outlet, useParams } from 'react-router-dom';
import type { T } from '@shared/pairql/dashboard';
import Current from '../../../environment';
import { Key, useQuery } from '../../../hooks';

export type SuperviseDeviceContext = {
  code: string;
  claimData?: T.GetClaimDeviceData.Output;
  deviceStatus?: T.GetSupervisionDeviceStatus.Output;
};

const SuperviseDevice: React.FC = () => {
  const { code = `` } = useParams<{ code: string }>();
  return <Outlet context={{ code }} />;
};

export default SuperviseDevice;

export const SuperviseDeviceClaimLoader: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const { code = `` } = useParams<{ code: string }>();

  const query = useQuery(Key.claimDeviceData(code), () =>
    Current.api.getClaimDeviceData({ code: parseInt(code ?? `0`, 10) }),
  );

  if (query.isPending) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  return <>{children}</>;
};

export const SuperviseDeviceStatusLoader: React.FC<{
  children: (data: T.GetSupervisionDeviceStatus.Output) => React.ReactNode;
}> = ({ children }) => {
  const { code = `` } = useParams<{ code: string }>();

  const query = useQuery(Key.supervisionDeviceStatus(code), () =>
    Current.api.getSupervisionDeviceStatus({ code: parseInt(code ?? `0`, 10) }),
  );

  if (query.isPending) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  return <>{children(query.data)}</>;
};
