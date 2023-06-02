import React from 'react';
import { Loading, ListUsers, ApiErrorMessage } from '@dash/components';
import type { EditUser } from '@dash/components';
import type { Device, DeviceModelFamily } from '@dash/types';
import Current from '../../environment';
import { useQuery, Key, useMutation } from '../../hooks';
import ReqState from '../../lib/ReqState';

const Users: React.FC = () => {
  const query = useQuery(Key.users, Current.api.getUsers);

  const addDevice = useMutation((userId: UUID) =>
    Current.api.createPendingAppConnection({ userId }),
  );

  if (query.isLoading) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  return (
    <ListUsers
      users={query.data.map((user) => ({
        id: user.id,
        name: user.name,
        numKeychains: user.keychains.length,
        numKeys: user.keychains.reduce((acc, keychain) => acc + keychain.numKeys, 0),
        devices: user.devices.map(deviceProps),
        screenshotsEnabled: user.screenshotsEnabled,
        keystrokesEnabled: user.keyloggingEnabled,
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
    case `unknown`:
      return `laptop`;
  }
}

export function deviceProps(
  apiDevice: Device,
): React.ComponentProps<typeof EditUser>['devices'][0] {
  return {
    id: apiDevice.id,
    model: apiDevice.modelTitle,
    status: apiDevice.isOnline ? `online` : `offline`,
    icon: familyToIcon(apiDevice.modelFamily),
  };
}
