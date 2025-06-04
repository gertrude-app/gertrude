import { ApiErrorMessage, Loading } from '@dash/components';
import { EditUser } from '@dash/components';
import { type User, defaults } from '@dash/types';
import React, { useEffect, useMemo, useReducer } from 'react';
import { Navigate, useParams } from 'react-router-dom';
import { v4 as uuid } from 'uuid';
import type { RequestPublicKeychain } from '@dash/types';
import Current from '../../environment';
import {
  Key,
  useConfirmableDelete,
  useMutation,
  useQuery,
  useSelectableKeychains,
} from '../../hooks';
import ReqState from '../../lib/ReqState';
import * as empty from '../../lib/empty';
import { isDirty } from '../../lib/helpers';
import reducer from '../../reducers/user-reducer';
import { deviceProps } from './Users';

const UserRoute: React.FC = () => {
  const { userId: id = `` } = useParams<{ userId: string }>();
  const [state, dispatch] = useReducer(reducer, {});
  const queryKey = Key.user(id);
  const getKeychains = useSelectableKeychains();
  const deleteChild = useConfirmableDelete(`child`, { id });
  const deleteComputerUser = useConfirmableDelete(`computerUser`, {
    invalidating: [queryKey],
  });

  const getUser = useQuery(queryKey, () => Current.api.getUser(id), {
    onReceive: (user) => dispatch({ type: `setUser`, user }),
    enabled: id !== `new` && state.user?.isNew !== true,
  });

  const addDevice = useMutation((userId: UUID) =>
    Current.api.createPendingAppConnection({ userId }),
  );

  const saveUser = useMutation(
    (user: Editable<User>) =>
      Current.api.saveUser({
        id: user.draft.id,
        isNew: user.isNew ?? false,
        name: user.draft.name,
        keyloggingEnabled: user.draft.keyloggingEnabled,
        screenshotsEnabled: user.draft.screenshotsEnabled,
        screenshotsFrequency: user.draft.screenshotsFrequency,
        screenshotsResolution: user.draft.screenshotsResolution,
        showSuspensionActivity: user.draft.showSuspensionActivity,
        downtime: user.draft.downtime,
        keychains: user.draft.keychains.map(({ id, schedule }) => ({ id, schedule })),
        blockedApps: user.draft.blockedApps,
      }),
    {
      onSuccess: () => dispatch({ type: `userSaved` }),
      invalidating: [queryKey],
      toast: `save:user`,
    },
  );

  const requestPublicKeychain = useMutation((input: RequestPublicKeychain.Input) =>
    Current.api.requestPublicKeychain({
      searchQuery: input.searchQuery,
      description: input.description,
    }),
  );

  const newUserId = useMemo(() => uuid(), []);
  useEffect(() => {
    if (id === `new`) {
      dispatch({ type: `setUser`, user: empty.user(newUserId), new: true });
    }
  }, [id, newUserId]);

  if (id === `new`) {
    return <Navigate to={`/children/${newUserId}`} replace />;
  }

  if (deleteChild.state === `success`) {
    return <Navigate to="/children" />;
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
      showSuspensionActivity={draft.showSuspensionActivity}
      setShowSuspensionActivity={(show) =>
        dispatch({ type: `setShowSuspensionActivity`, show })
      }
      removeKeychain={(id) => dispatch({ type: `removeKeychain`, id })}
      keychains={draft.keychains}
      devices={original.devices.map(deviceProps)}
      deleteUser={deleteChild}
      startAddDevice={() => addDevice.mutate(id)}
      dismissAddDevice={() => addDevice.reset()}
      addDeviceRequest={ReqState.fromMutation(addDevice)}
      downtime={draft.downtime ?? defaults.timeWindow()}
      downtimeEnabled={!!draft.downtime}
      setDowntimeEnabled={(enabled) => dispatch({ type: `setDowntimeEnabled`, enabled })}
      setDowntime={(downtime) => dispatch({ type: `setDowntime`, downtime })}
      deleteDevice={deleteComputerUser}
      saveButtonDisabled={
        !isDirty(state.user) || draft.name.trim() === `` || saveUser.isPending
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
        if (addingKeychain) {
          dispatch({ type: `addKeychain`, keychain: addingKeychain });
        }
        dispatch({ type: `setAddingKeychain`, keychain: undefined });
      }}
      onDismissAddKeychain={() =>
        dispatch({ type: `setAddingKeychain`, keychain: undefined })
      }
      addingKeychain={addingKeychain}
      fetchSelectableKeychainsRequest={
        addingKeychain === undefined ? undefined : ReqState.fromQuery(getKeychains)
      }
      keychainSchedule={addingKeychain?.schedule}
      setAddingKeychainSchedule={(schedule) =>
        dispatch({ type: `setAddingKeychainSchedule`, schedule })
      }
      setAssignedKeychainSchedule={(id, schedule) =>
        dispatch({ type: `setKeychainSchedule`, id, schedule })
      }
      blockedApps={draft.blockedApps}
      newBlockedAppIdentifier={state.newBlockedAppIdentifier ?? ``}
      updateNewBlockedAppIdentifier={(identifier) =>
        dispatch({ type: `updateNewBlockedAppIdentifier`, identifier })
      }
      addNewBlockedApp={() => dispatch({ type: `addNewBlockedApp` })}
      removeBlockedApp={(id) => dispatch({ type: `removeBlockedApp`, id })}
      setBlockedAppSchedule={(id, schedule) =>
        dispatch({ type: `setBlockedAppSchedule`, id, schedule })
      }
      onRequestPublicKeychain={(searchQuery: string, description: string) =>
        requestPublicKeychain.mutate({ searchQuery, description })
      }
      requestPublicKeychainRequest={ReqState.fromMutation(requestPublicKeychain)}
    />
  );
};

export default UserRoute;

// helpers
