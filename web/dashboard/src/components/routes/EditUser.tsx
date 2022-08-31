import React, { useEffect } from 'react';
import EditUser from '@shared/dashboard/Users/EditUser';
import { useParams } from 'react-router-dom';
import Loading from '@shared/Loading';
import { useDispatch, useSelector } from '../../redux/hooks';
import ApiErrorMessage from '../ApiErrorMessage';
import {
  GetUser_user_devices,
  GetUser_user_keychains,
} from '../../api/users/__generated__/GetUser';
import { familyToIcon } from './Users';
import { fetchUser, userUpdated, UserUpdate } from '../../redux/slice-users';
import { isDirty } from '../../redux/helpers';

const EditUserContainer: React.FC = () => {
  const dispatch = useDispatch();
  const { userId = `` } = useParams<{ userId: string }>();
  const { request, user } = useSelector((state) => ({
    user: state.users.users[userId],
    request: state.users.fetchUserRequest[userId],
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
        keychains={user.draft.keychains.map(keychainProps)}
        devices={user.draft.devices.map(deviceProps)}
        isDirty={isDirty(user)}
      />
    );
  }

  if (!request || request.state === `ongoing` || request.state === `idle`) {
    return <Loading />;
  }

  if (request.state === `failed`) {
    return <ApiErrorMessage error={request.error} />;
  }

  return <ApiErrorMessage error={{ type: `actionable`, message: `User not found` }} />;
};

export default EditUserContainer;

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
