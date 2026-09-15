import { ApiErrorMessage, ListChildren, Loading } from '@dash/components';
import React from 'react';
import type { DeviceModelFamily } from '@dash/types';
import Current from '../../environment';
import { Key, useComputerStatuses, useMutation, useQuery } from '../../hooks';
import ReqState from '../../lib/ReqState';

const Users: React.FC = () => {
  const query = useQuery(Key.children, Current.api.getChildren);
  const statusesQuery = useComputerStatuses();

  const addDevice = useMutation((childId: UUID) =>
    Current.api.macAppConnectionCode({ childId }),
  );
  const startTrial = useMutation(() => Current.api.startFullTrial());

  if (query.isPending) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  const children = query.data.map((child) => ({
    ...child,
    computers: child.computers.map((computer) => ({
      ...computer,
      status:
        statusesQuery.data?.find((status) => status.computerUserId === computer.id)
          ?.status ?? computer.status,
    })),
  }));

  return (
    <ListChildren
      users={children.map((child) => ({
        id: child.id,
        name: child.name,
        computers: child.computers,
        iosDevices: child.iosDevices,
      }))}
      startAddDevice={(userId) => addDevice.mutate(userId)}
      dismissAddDevice={() => addDevice.reset()}
      addDeviceRequest={ReqState.fromMutation(addDevice)}
      onStartTrial={() => startTrial.mutate(undefined)}
    />
  );
};

export default Users;

export function familyToIcon(family: DeviceModelFamily): `laptop` | `desktop` {
  switch (family) {
    case `iMac`:
    case `pro`:
    case `studio`:
    case `mini`:
      return `desktop`;
    case `macBookAir`:
    case `macBookPro`:
    case `macBook`:
    case `macBookNeo`:
    case `unknown`:
      return `laptop`;
  }
}
