import React, { useEffect } from 'react';
import { Navigate, useParams } from 'react-router-dom';
import { Loading, EditUser } from '@dash/components';
import { isUnsaved, unsavedId } from '@dash/utils';
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
  createPendingAppConnection,
  addDeviceDismissed,
  addKeychainClicked,
  keychainSelected,
  keychainAdded,
  addKeychainModalDismissed,
} from '../../redux/slice-users';
import { isDirty, Query, Req } from '../../redux/helpers';
import { GetUser_user_devices } from '../../api/users/__generated__/GetUser';
import { QueryProps } from '../../redux/store';
import useSelectableKeychains from '../../hooks/selectable-keychains';

const User: React.FC = () => {
  const dispatch = useDispatch();
  const { userId: id = `` } = useParams<{ userId: string }>();
  const [query, shouldFetch] = useSelector(queryProps(dispatch, id));

  useEffect(() => {
    shouldFetch && dispatch(fetchUser(id));
  }, [dispatch, id, shouldFetch]);

  if (query.state === `entityDeleted`) {
    return <Navigate to={query.redirectUrl} />;
  }

  if (query.state === `shouldFetch` || query.state === `ongoing`) {
    return <Loading />;
  }

  if (query.state === `failed`) {
    return <ApiErrorMessage entity="User" error={query.error} />;
  }

  return <EditUser {...query.props} />;
};

export default User;

export const queryProps: QueryProps<typeof EditUser, UUID> =
  (dispatch, userId) => (appState) => {
    const id = userId === `new` ? unsavedId() : userId;
    const state = appState.users;
    const fetch = state.fetchUserRequest[id];
    const selectableKeychains = useSelectableKeychains(
      state.adding.keychain !== undefined,
    );

    if (!isUnsaved(id) && fetch?.state !== `succeeded`) {
      return [Req.toUnresolvedQuery(fetch), fetch?.state !== `failed`];
    }

    const editable = state.users[id];

    if (!editable && state.deleted.includes(userId)) {
      return [Query.redirectDeleted(`/users`), false];
    } else if (!editable) {
      return [Query.unexpectedError(), false];
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
        setScreenshotsResolution: (value) =>
          set({ type: `screenshotsResolution`, value }),
        screenshotsFrequency: user.screenshotsFrequency,
        setScreenshotsFrequency: (value) => set({ type: `screenshotsFrequency`, value }),
        removeKeychain: (keychainId) =>
          dispatch(userUpdated({ id, type: `removeKeychain`, value: keychainId })),
        keychains: user.keychains,
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
        startAddDevice: () => dispatch(createPendingAppConnection(id)),
        dismissAddDevice: () => dispatch(addDeviceDismissed()),
        addDeviceRequest: state.addDeviceRequest,
        onAddKeychainClicked: () => dispatch(addKeychainClicked()),
        onSelectKeychainToAdd: (keychain) => dispatch(keychainSelected(keychain)),
        onConfirmAddKeychain: () => dispatch(keychainAdded(id)),
        onDismissAddKeychain: () => dispatch(addKeychainModalDismissed()),
        selectingKeychain: state.adding?.keychain,
        fetchSelectableKeychainsRequest:
          state.adding?.keychain === undefined ? undefined : selectableKeychains,
      }),
      false,
    ];
  };

// helpers

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
