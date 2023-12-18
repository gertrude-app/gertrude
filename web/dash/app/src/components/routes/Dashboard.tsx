import { Loading, ApiErrorMessage } from '@dash/components';
import React from 'react';
import { Dashboard } from '@dash/components';
import Current from '../../environment';
import { useQuery, Key, useMutation } from '../../hooks';
import ReqState from '../../lib/ReqState';

const DashboardRoute: React.FC = () => {
  const widgetsQuery = useQuery(Key.dashboard, Current.api.getDashboardWidgets);
  const addDevice = useMutation((userId: UUID) =>
    Current.api.createPendingAppConnection({ userId }),
  );

  if (widgetsQuery.isPending) {
    return <Loading />;
  }

  if (widgetsQuery.isError) {
    return <ApiErrorMessage error={widgetsQuery.error} />;
  }

  return (
    <Dashboard
      startAddDevice={(userId) => addDevice.mutate(userId)}
      dismissAddDevice={() => addDevice.reset()}
      addDeviceRequest={ReqState.fromMutation(addDevice)}
      {...widgetsQuery.data}
    />
  );
};

export default DashboardRoute;
