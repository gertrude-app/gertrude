import React, { useEffect } from 'react';
import { Loading, ListUsers, ApiErrorMessage } from '@dash/components';
import { Family } from '@dash/types';
import { typesafe } from '@shared/ts-utils';
import { useDispatch, useSelector } from '../../redux/hooks';
import {
  addDeviceDismissed,
  createPendingAppConnection,
  fetchUsers,
} from '../../redux/slice-users';

const Users: React.FC = () => {
  const dispatch = useDispatch();
  const { users, listRequest, addDeviceRequest } = useSelector((state) => ({
    listRequest: state.users.listRequest,
    addDeviceRequest: state.users.addDeviceRequest,
    users: typesafe
      .objectValues(state.users.entities)
      .filter((editable) => !editable.isNew)
      .map((editable) => editable.original),
  }));

  useEffect(() => {
    listRequest.state === `idle` && dispatch(fetchUsers());
  }, [dispatch, listRequest, listRequest.state]);

  if (listRequest.state === `failed`) {
    return <ApiErrorMessage error={listRequest.error} />;
  }

  if (listRequest.state === `idle` || listRequest.state === `ongoing`) {
    return <Loading />;
  }

  return (
    <ListUsers
      users={users.map((resource) => ({
        id: resource.id,
        name: resource.name,
        numKeychains: resource.keychains.length,
        numKeys: resource.keychains.reduce((acc, keychain) => acc + keychain.numKeys, 0),
        devices: resource.devices.map((device) => ({
          id: device.id,
          model: device.model.title,
          status: device.isOnline ? `online` : `offline`,
          icon: familyToIcon(device.model.family),
        })),
        screenshotsEnabled: resource.screenshotsEnabled,
        keystrokesEnabled: resource.keyloggingEnabled,
      }))}
      startAddDevice={(userId) => dispatch(createPendingAppConnection(userId))}
      dismissAddDevice={() => dispatch(addDeviceDismissed())}
      addDeviceRequest={addDeviceRequest}
    />
  );
};

export default Users;

export function familyToIcon(family: Family): `laptop` | `desktop` {
  switch (family) {
    case Family.iMac:
    case Family.pro:
    case Family.studio:
    case Family.mini:
      return `desktop`;
    case Family.macBookAir:
    case Family.macBookPro:
    case Family.unknown:
      return `laptop`;
  }
}
