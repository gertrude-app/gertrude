import React, { useEffect } from 'react';
import Loading from '@shared/Loading';
import ListUsers from '@dashboard/Users/List';
import { isUnsaved } from '@dashboard/lib/id';
import { Family } from '@dashboard/types/GraphQL';
import { useDispatch, useSelector } from '../../redux/hooks';
import { addDeviceDismissed, createUserToken, fetchUsers } from '../../redux/slice-users';
import ApiErrorMessage from '../ApiErrorMessage';
import * as typesafe from '../../lib/typesafe';

const Users: React.FC = () => {
  const dispatch = useDispatch();
  const { users, listRequest, addDeviceRequest } = useSelector((state) => ({
    listRequest: state.users.listRequest,
    addDeviceRequest: state.users.addDeviceRequest,
    users: typesafe
      .objectValues(state.users.users)
      .map((editable) => editable.original)
      .filter((user) => !isUnsaved(user.id)),
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
        numKeys: resource.keychains.reduce(
          (acc, keychain) => acc + keychain.keys.length,
          0,
        ),
        devices: resource.devices.map((device) => ({
          id: device.id,
          model: device.model.title,
          status: device.isOnline ? `online` : `offline`,
          icon: familyToIcon(device.model.family),
        })),
        screenshotsEnabled: resource.screenshotsEnabled,
        keystrokesEnabled: resource.keyloggingEnabled,
      }))}
      startAddDevice={(userId) => dispatch(createUserToken(userId))}
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
