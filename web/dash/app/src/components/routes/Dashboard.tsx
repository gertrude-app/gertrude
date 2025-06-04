import { ApiErrorMessage, Loading } from '@dash/components';
import { Dashboard } from '@dash/components';
import React from 'react';
import Current from '../../environment';
import { Key, useDeleteEntity, useMutation, useQuery } from '../../hooks';
import ReqState from '../../lib/ReqState';

const DashboardRoute: React.FC = () => {
  const widgetsQuery = useQuery(Key.dashboard, Current.api.dashboardWidgets);
  const deleteAnnouncement = useDeleteEntity(`announcement`);
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
      startAddDevice={addDevice.mutate}
      dismissAddDevice={addDevice.reset}
      addDeviceRequest={ReqState.fromMutation(addDevice)}
      dismissAnnouncement={deleteAnnouncement.mutate}
      unlockRequests={widgetsQuery.data.unlockRequests}
      childData={widgetsQuery.data.children}
      childActivitySummaries={widgetsQuery.data.childActivitySummaries}
      recentScreenshots={widgetsQuery.data.recentScreenshots}
      numParentNotifications={widgetsQuery.data.numParentNotifications}
      announcement={widgetsQuery.data.announcement}
    />
  );
};

export default DashboardRoute;
