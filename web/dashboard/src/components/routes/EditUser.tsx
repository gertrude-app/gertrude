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
import { fetchUser } from '../../redux/slice-users';

const EditUserContainer: React.FC = () => {
  const { userId = `` } = useParams<{ userId: string }>();
  const { request } = useSelector((state) => ({ request: state.users.users[userId] }));
  const dispatch = useDispatch();

  useEffect(() => {
    dispatch(fetchUser(userId));
  }, [dispatch, userId]);

  if (!request || request.state === `ongoing` || request.state === `idle`) {
    return <Loading />;
  }

  if (request.state === `failed`) {
    return <ApiErrorMessage error={request.error} />;
  }

  const user = request.payload;
  return (
    <EditUser
      name={user.name}
      setName={() => {}}
      keyloggingEnabled={user.keyloggingEnabled}
      setKeyloggingEnabled={() => {}}
      screenshotsEnabled={user.screenshotsEnabled}
      setScreenshotsEnabled={() => {}}
      screenshotsResolution={user.screenshotsResolution}
      setScreenshotsResolution={() => {}}
      screenshotsFrequency={user.screenshotsFrequency}
      setScreenshotsFrequency={() => {}}
      keychains={user.keychains.map(keychainProps)}
      devices={user.devices.map(deviceProps)}
    />
  );
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
