import { ApiErrorMessage, Loading } from '@dash/components';
import { Dashboard } from '@dash/components';
import React from 'react';
import type { PrepIOSAppConnection } from '@dash/types';
import Current from '../../environment';
import { Key, useDeleteEntity, useMutation, useQuery } from '../../hooks';
import ReqState from '../../lib/ReqState';

const DashboardRoute: React.FC = () => {
  const widgetsQuery = useQuery(Key.dashboard, Current.api.dashboardWidgets, {
    refetchIntervalSeconds: 9 * 60, // img sig expires in 10 min
  });
  const deleteAnnouncement = useDeleteEntity(`announcement`);
  const addDevice = useMutation((childId: UUID) =>
    Current.api.macAppConnectionCode({ childId }),
  );
  const startTrial = useMutation(() => Current.api.startFullTrial());
  const prepIOSConnection = useMutation((input: PrepIOSAppConnection.Input) =>
    Current.api.prepIOSAppConnection(input),
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
      onStartTrial={() => startTrial.mutate(undefined)}
      dismissAnnouncement={deleteAnnouncement.mutate}
      prepIOSConnection={prepIOSConnection.mutate}
      iosSetupRequest={ReqState.fromMutation(prepIOSConnection)}
      resetIOSSetup={prepIOSConnection.reset}
      unlockRequests={widgetsQuery.data.unlockRequests}
      childData={widgetsQuery.data.children}
      childActivitySummaries={widgetsQuery.data.childActivitySummaries}
      recentScreenshots={widgetsQuery.data.recentScreenshots}
      numParentNotifications={widgetsQuery.data.numParentNotifications}
      announcement={widgetsQuery.data.announcement}
      pendingIosDevices={widgetsQuery.data.pendingIOSDevices}
    />
  );
};

export default DashboardRoute;
