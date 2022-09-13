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
  upsertUser,
  userEntityDeleteStarted,
  userEntityDeleteCanceled,
  deleteDevice,
  deleteUser,
} from '../../redux/slice-users';
import { isDirty, Query, Req } from '../../redux/helpers';
import {
  GetUser_user_devices,
  GetUser_user_keychains,
} from '../../api/users/__generated__/GetUser';
import { QueryProps } from '../../redux/store';
import { isUnsaved, unsavedId } from '../shared/lib/id';

const User: React.FC = () => {
  const dispatch = useDispatch();
  const { userId = `` } = useParams<{ userId: string }>();
  const [query, shouldFetch] = useSelector(queryProps(dispatch));

  useEffect(() => {
    shouldFetch && dispatch(fetchUser(userId));
  }, [dispatch, userId, shouldFetch]);

  if (query.state === `shouldFetch` || query.state === `ongoing`) {
    return <Loading />;
  }

  if (query.state === `failed`) {
    return <ApiErrorMessage error={query.error} />;
  }

  return <EditUser {...query.props} />;
};

export default User;

export const queryProps: QueryProps<typeof EditUser> = (dispatch) => (appState) => {
  const { userId = `` } = useParams<{ userId: string }>();
  const id = userId === `new` ? unsavedId() : userId;
  const state = appState.users;
  const fetch = state.fetchUserRequest[id];
  if (!isUnsaved(id) && fetch?.state !== `succeeded`) {
    return [Req.toUnresolvedQuery(fetch), fetch?.state !== `failed`];
  }

  const editable = state.users[id];
  if (!editable) {
    // we get in this state briefly after a user is deleted
    return [{ state: `ongoing` }, false];
  }

  const user = editable.draft;
  const update = state.updateUserRequest[id];
  const deleteDeviceId = state.deleting.device;
  const deleteUserId = state.deleting.user;

  function set(arg: Partial<UserUpdate>): void {
    dispatch(userUpdated({ id, ...arg } as UserUpdate));
  }

  return [
    Query.resolve({
      isNew: isUnsaved(id),
      name: user.name,
      setName: (value) => set({ type: `name`, value }),
      keyloggingEnabled: user.keyloggingEnabled,
      setKeyloggingEnabled: (value) => set({ type: `keyloggingEnabled`, value }),
      screenshotsEnabled: user.screenshotsEnabled,
      setScreenshotsEnabled: (value) => set({ type: `screenshotsEnabled`, value }),
      screenshotsResolution: user.screenshotsResolution,
      setScreenshotsResolution: (value) => set({ type: `screenshotsResolution`, value }),
      screenshotsFrequency: user.screenshotsFrequency,
      setScreenshotsFrequency: (value) => set({ type: `screenshotsFrequency`, value }),
      removeKeychain: (id) =>
        dispatch(userUpdated({ id, type: `removeKeychain`, value: id })),
      keychains: user.keychains.map(keychainProps),
      devices: user.devices.map(deviceProps),
      saveButtonDisabled:
        !isUnsaved(id) && (!isDirty(editable) || update?.state === `ongoing`),
      onSave: () => dispatch(upsertUser(id)),
      deleteUser: {
        id: deleteUserId,
        start: () => dispatch(userEntityDeleteStarted({ type: `user`, id })),
        confirm: () => dispatch(deleteUser(deleteUserId ?? ``)),
        cancel: () => dispatch(userEntityDeleteCanceled(`user`)),
      },
      deleteDevice: {
        id: deleteDeviceId,
        start: (id) => dispatch(userEntityDeleteStarted({ type: `device`, id })),
        confirm: () => dispatch(deleteDevice(deleteDeviceId ?? ``)),
        cancel: () => dispatch(userEntityDeleteCanceled(`device`)),
      },
    }),
    false,
  ];
};

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
