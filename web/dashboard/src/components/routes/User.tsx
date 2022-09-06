import React, { useEffect } from 'react';
import EditUser from '@dashboard/Users/EditUser';
import { useParams } from 'react-router-dom';
import Loading from '@shared/Loading';
import { useDispatch, useSelector } from '../../redux/hooks';
import ApiErrorMessage from '../ApiErrorMessage';
import { familyToIcon } from './Users';
import {
  fetchUser,
  userUpdated,
  UserUpdate,
  updateUser,
  startEntityDelete,
  cancelEntityDelete,
  deleteDevice,
} from '../../redux/slice-users';
import { isDirty } from '../../redux/helpers';
import {
  GetUser_user_devices,
  GetUser_user_keychains,
} from '../../api/users/__generated__/GetUser';

const User: React.FC = () => {
  const dispatch = useDispatch();
  const { userId = `` } = useParams<{ userId: string }>();
  const { fetch, update, user, deleteDeviceId } = useSelector((state) => ({
    user: state.users.users[userId],
    fetch: state.users.fetchUserRequest[userId],
    update: state.users.updateUserRequest[userId],
    deleteDeviceId: state.users.deleting.device,
  }));

  useEffect(() => {
    !user && dispatch(fetchUser(userId));
  }, [dispatch, user, userId]);

  function set(arg: Partial<UserUpdate>): void {
    dispatch(userUpdated({ id: userId, ...arg } as UserUpdate));
  }

  if (user) {
    return (
      <EditUser
        name={user.draft.name}
        setName={(value) => set({ type: `name`, value })}
        keyloggingEnabled={user.draft.keyloggingEnabled}
        setKeyloggingEnabled={(value) => set({ type: `keyloggingEnabled`, value })}
        screenshotsEnabled={user.draft.screenshotsEnabled}
        setScreenshotsEnabled={(value) => set({ type: `screenshotsEnabled`, value })}
        screenshotsResolution={user.draft.screenshotsResolution}
        setScreenshotsResolution={(value) =>
          set({ type: `screenshotsResolution`, value })
        }
        screenshotsFrequency={user.draft.screenshotsFrequency}
        setScreenshotsFrequency={(value) => set({ type: `screenshotsFrequency`, value })}
        removeKeychain={(id) =>
          dispatch(userUpdated({ id: userId, type: `removeKeychain`, value: id }))
        }
        keychains={user.draft.keychains.map(keychainProps)}
        devices={user.draft.devices.map(deviceProps)}
        saveButtonDisabled={!isDirty(user) || update?.state === `ongoing`}
        onSave={() => dispatch(updateUser(userId))}
        deleteDevice={{
          id: deleteDeviceId,
          start: (id) => dispatch(startEntityDelete({ type: `device`, id })),
          confirm: () => dispatch(deleteDevice(deleteDeviceId ?? ``)),
          cancel: () => dispatch(cancelEntityDelete(`device`)),
        }}
      />
    );
  }

  if (!fetch || fetch.state === `ongoing` || fetch.state === `idle`) {
    return <Loading />;
  }

  if (fetch.state === `failed`) {
    return <ApiErrorMessage error={fetch.error} />;
  }

  return <ApiErrorMessage error={{ type: `actionable`, message: `User not found` }} />;
};

export default User;

// helpers

function keychainProps(
  apiKeychain: GetUser_user_keychains,
): React.ComponentProps<typeof EditUser>['keychains'][0] {
  return {
    id: apiKeychain.id,
    name: apiKeychain.name,
    description: apiKeychain.description ?? ``,
    isPublic: apiKeychain.isPublic,
    keys: apiKeychain.keys.length,
  };
}

function deviceProps(
  apiDevice: GetUser_user_devices,
): React.ComponentProps<typeof EditUser>['devices'][0] {
  return {
    id: apiDevice.id,
    model: apiDevice.model.title,
    status: apiDevice.isOnline ? `online` : `offline`,
    icon: familyToIcon(apiDevice.model.family),
  };
}
