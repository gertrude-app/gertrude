import React, { useEffect, useMemo } from 'react';
import { v4 as uuid } from 'uuid';
import { Navigate, useParams } from 'react-router-dom';
import { Loading, EditUser, ApiErrorMessage } from '@dash/components';
import type { Device } from '@dash/types';
import type { UserUpdate } from '../../redux/slice-users';
import type { QueryProps } from '../../redux/store';
import { newUserRouteVisited } from '../../redux/slice-users';
import { useDispatch, useSelector } from '../../redux/hooks';
import {
  fetchUser,
  userUpdated,
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
import useSelectableKeychains from '../../hooks/selectable-keychains';
import { familyToIcon } from './Users';

const User: React.FC = () => {
  const { userId: id = `` } = useParams<{ userId: string }>();
  const newUserId = useMemo(() => uuid(), []);
  const dispatch = useDispatch();
  const [query, shouldFetch] = useSelector(queryProps(dispatch, id));

  useEffect(() => {
    shouldFetch && dispatch(fetchUser(id));
    id === `new` && dispatch(newUserRouteVisited(newUserId));
  }, [dispatch, id, shouldFetch, newUserId]);

  if (id === `new`) {
    return <Navigate to={`/users/${newUserId}`} replace />;
  }

  if (query.state === `entityDeleted`) {
    return <Navigate to={query.redirectUrl} />;
  }

  if (query.state === `shouldFetch` || query.state === `ongoing`) {
    return <Loading />;
  }

  if (query.state === `failed`) {
    return <ApiErrorMessage error={query.error} />;
  }

  return <EditUser {...query.props} />;
};

export default User;

export const queryProps: QueryProps<typeof EditUser, UUID> =
  (dispatch, id) => (appState) => {
    const state = appState.users;
    const fetch = state.fetchUserRequest[id];
    const editable = state.entities[id];
    const selectableKeychains = useSelectableKeychains(
      state.adding.keychain !== undefined,
    );

    if (id === `new`) {
      return [{ state: `ongoing` }, false];
    }

    if (!editable && fetch?.state !== `succeeded`) {
      return [Req.toUnresolvedQuery(fetch), fetch?.state !== `failed`];
    }

    if (!editable && state.deleted.includes(id)) {
      return [Query.redirectDeleted(`/users`), false];
    } else if (!editable) {
      return [Query.unexpectedError(`c989c73a`, `missing user`), false];
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
        isNew: editable.isNew === true,
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
          !isDirty(editable) ||
          update?.state === `ongoing` ||
          editable.draft.name.trim() === ``,
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
        startAddDevice: () => dispatch(createPendingAppConnection({ userId: id })),
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
  apiDevice: Device,
): React.ComponentProps<typeof EditUser>['devices'][0] {
  return {
    id: apiDevice.id,
    model: apiDevice.modelTitle,
    status: apiDevice.isOnline ? `online` : `offline`,
    icon: familyToIcon(apiDevice.modelFamily),
  };
}
