import { ApiErrorMessage, Loading } from '@dash/components';
import { Dashboard } from '@dash/components';
import React from 'react';
import type { PrepIOSAppConnection } from '@dash/types';
import Current from '../../environment';
import {
  Key,
  useComputerStatuses,
  useDeleteEntity,
  useMutation,
  useQuery,
} from '../../hooks';
import ReqState from '../../lib/ReqState';

const DashboardRoute: React.FC = () => {
  const widgetsQuery = useQuery(Key.dashboard, Current.api.dashboardWidgets, {
    refetchIntervalSeconds: 9 * 60, // img sig expires in 10 min
  });
  const statusesQuery = useComputerStatuses();
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

  const childData = widgetsQuery.data.children.map((child) => ({
    ...child,
    devices: child.devices.map((device) => {
      if (device.platform !== `mac` || !device.computerUserId) return device;
      const status = statusesQuery.data?.find(
        (candidate) => candidate.computerUserId === device.computerUserId,
      );
      return status ? { ...device, macStatus: status.status } : device;
    }),
  }));

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
      childData={childData}
      childActivitySummaries={widgetsQuery.data.childActivitySummaries}
      recentScreenshots={widgetsQuery.data.recentScreenshots}
      numParentNotifications={widgetsQuery.data.numParentNotifications}
      announcement={widgetsQuery.data.announcement}
      pendingIosDevices={widgetsQuery.data.pendingIOSDevices}
    />
  );
};

export default DashboardRoute;
