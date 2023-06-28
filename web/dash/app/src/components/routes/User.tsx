import { v4 as uuid } from 'uuid';
import { Navigate, useParams } from 'react-router-dom';
import { Loading, ApiErrorMessage } from '@dash/components';
import React, { useEffect, useMemo, useReducer } from 'react';
import { EditUser } from '@dash/components';
import type { User } from '@dash/types';
import * as empty from '../../lib/empty';
import { isDirty } from '../../lib/helpers';
import Current from '../../environment';
import {
  useMutation,
  Key,
  useQuery,
  useSelectableKeychains,
  useConfirmableDelete,
} from '../../hooks';
import ReqState from '../../lib/ReqState';
import reducer from '../../reducers/user-reducer';
import { deviceProps } from './Users';

const UserRoute: React.FC = () => {
  const { userId: id = `` } = useParams<{ userId: string }>();
  const [state, dispatch] = useReducer(reducer, {});
  const queryKey = Key.user(id);
  const getKeychains = useSelectableKeychains();
  const deleteUser = useConfirmableDelete(`user`, { id });
  const deleteDevice = useConfirmableDelete(`device`, { invalidating: [queryKey] });

  const getUser = useQuery(queryKey, () => Current.api.getUser(id), {
    onReceive: (user) => dispatch({ type: `setUser`, user }),
    enabled: id !== `new` && state.user?.isNew !== true,
  });

  const addDevice = useMutation((userId: UUID) =>
    Current.api.createPendingAppConnection({ userId }),
  );

  const saveUser = useMutation(
    (editableUser: Editable<User>) =>
      Current.api.saveUser({
        id: editableUser.draft.id,
        name: editableUser.draft.name,
        keyloggingEnabled: editableUser.draft.keyloggingEnabled,
        screenshotsEnabled: editableUser.draft.screenshotsEnabled,
        screenshotsFrequency: editableUser.draft.screenshotsFrequency,
        screenshotsResolution: editableUser.draft.screenshotsResolution,
        isNew: editableUser.isNew ?? false,
        keychainIds: editableUser.draft.keychains.map(({ id }) => id),
      }),
    {
      onSuccess: () => dispatch({ type: `userSaved` }),
      invalidating: [queryKey],
      toast: `save:user`,
    },
  );

  const newUserId = useMemo(() => uuid(), []);
  useEffect(() => {
    id === `new` && dispatch({ type: `setUser`, user: empty.user(newUserId), new: true });
  }, [id, newUserId]);

  if (id === `new`) {
    return <Navigate to={`/users/${newUserId}`} replace />;
  }

  if (deleteUser.state === `success`) {
    return <Navigate to="/users" />;
  }

  if (getUser.isError) {
    return <ApiErrorMessage error={getUser.error} />;
  }

  if (!state.user) {
    return <Loading />;
  }

  const { user, addingKeychain } = state;
  const { draft, original } = user;

  return (
    <EditUser
      isNew={state.user.isNew || false}
      name={draft.name}
      id={draft.id}
      setName={(name) => dispatch({ type: `setName`, name })}
      keyloggingEnabled={draft.keyloggingEnabled}
      setKeyloggingEnabled={(enabled) =>
        dispatch({ type: `setKeyloggingEnabled`, enabled })
      }
      screenshotsEnabled={draft.screenshotsEnabled}
      setScreenshotsEnabled={(enabled) =>
        dispatch({ type: `setScreenshotsEnabled`, enabled })
      }
      screenshotsResolution={draft.screenshotsResolution}
      setScreenshotsResolution={(resolution) =>
        dispatch({ type: `setScreenshotsResolution`, resolution })
      }
      screenshotsFrequency={draft.screenshotsFrequency}
      setScreenshotsFrequency={(frequency) =>
        dispatch({ type: `setScreenshotsFrequency`, frequency })
      }
      removeKeychain={(id) => dispatch({ type: `removeKeychain`, id })}
      keychains={draft.keychains}
      devices={original.devices.map(deviceProps)}
      deleteUser={deleteUser}
      startAddDevice={() => addDevice.mutate(id)}
      dismissAddDevice={() => addDevice.reset()}
      addDeviceRequest={ReqState.fromMutation(addDevice)}
      deleteDevice={deleteDevice}
      saveButtonDisabled={
        !isDirty(state.user) || draft.name.trim() === `` || saveUser.isLoading
      }
      onSave={() => saveUser.mutate(user)}
      onAddKeychainClicked={() => dispatch({ type: `setAddingKeychain`, keychain: null })}
      onSelectKeychainToAdd={(keychain) =>
        dispatch({
          type: `setAddingKeychain`,
          keychain: addingKeychain?.id === keychain.id ? null : keychain,
        })
      }
      onConfirmAddKeychain={() => {
        addingKeychain && dispatch({ type: `addKeychain`, keychain: addingKeychain });
        dispatch({ type: `setAddingKeychain`, keychain: undefined });
      }}
      onDismissAddKeychain={() =>
        dispatch({ type: `setAddingKeychain`, keychain: undefined })
      }
      selectingKeychain={addingKeychain}
      fetchSelectableKeychainsRequest={
        addingKeychain === undefined ? undefined : ReqState.fromQuery(getKeychains)
      }
    />
  );
};

export default UserRoute;

// helpers
