import React, { useEffect } from 'react';
import Loading from '@shared/Loading';
import ListUsers from '@shared/dashboard/Users/List';
import { useDispatch, useSelector } from '../../redux/hooks';
import { fetchUsers } from '../../redux/slice-users';
import ApiErrorMessage from '../ApiErrorMessage';
import { Family } from '../../graphqlTypes';
import * as typesafe from '../../lib/typesafe';

const Users: React.FC = () => {
  const dispatch = useDispatch();
  const { users, request } = useSelector((state) => ({
    request: state.users.listRequest,
    users: typesafe.objectValues(state.users.users).map((u) => u.original),
  }));

  useEffect(() => {
    request.state === `idle` && dispatch(fetchUsers());
  }, [dispatch, request, request.state]);

  if (request.state === `failed`) {
    return <ApiErrorMessage error={request.error} />;
  }

  if (request.state === `idle` || request.state === `ongoing`) {
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
