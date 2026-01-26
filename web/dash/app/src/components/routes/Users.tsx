import { ApiErrorMessage, ListChildren, Loading } from '@dash/components';
import React from 'react';
import type { DeviceModelFamily } from '@dash/types';
import Current from '../../environment';
import { Key, useMutation, useQuery } from '../../hooks';
import ReqState from '../../lib/ReqState';

const Users: React.FC = () => {
  const query = useQuery(Key.children, Current.api.getChildren);

  const addDevice = useMutation((userId: UUID) =>
    Current.api.createPendingAppConnection({ userId }),
  );

  if (query.isPending) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  return (
    <ListChildren
      users={query.data.map((child) => ({
        id: child.id,
        name: child.name,
        numKeychains: child.keychains.length,
        numKeys: child.keychains.reduce((acc, keychain) => acc + keychain.numKeys, 0),
        computers: child.computers,
        iosDevices: child.iosDevices,
        screenshotsEnabled: child.screenshotsEnabled,
        keystrokesEnabled: child.keyloggingEnabled,
      }))}
      startAddDevice={(userId) => addDevice.mutate(userId)}
      dismissAddDevice={() => addDevice.reset()}
      addDeviceRequest={ReqState.fromMutation(addDevice)}
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
    case `unknown`:
      return `laptop`;
  }
}
