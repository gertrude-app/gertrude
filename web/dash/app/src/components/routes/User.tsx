import { ApiErrorMessage, EditChild, Loading } from '@dash/components';
import { type Child, defaults } from '@dash/types';
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

const UserRoute: React.FC = () => {
  const { userId: id = `` } = useParams<{ userId: string }>();
  const [state, dispatch] = useReducer(reducer, {});
  const queryKey = Key.child(id);
  const getKeychains = useSelectableKeychains();
  const deleteChild = useConfirmableDelete(`child`, { id });
  const deleteComputerUser = useConfirmableDelete(`computerUser`, {
    invalidating: [queryKey],
  });

  const getChildQuery = useQuery(queryKey, () => Current.api.getChild(id), {
    onReceive: (child) => dispatch({ type: `setChild`, child }),
    enabled: id !== `new` && state.child?.isNew !== true,
  });

  const addDevice = useMutation((childId: UUID) =>
    Current.api.macAppConnectionCode({ childId }),
  );
  const startTrial = useMutation(() => Current.api.startFullTrial());

  const saveChild = useMutation(
    (child: Editable<Child>) =>
      Current.api.saveUser({
        id: child.draft.id,
        isNew: child.isNew ?? false,
        name: child.draft.name,
        keyloggingEnabled: child.draft.keyloggingEnabled,
        screenshotsEnabled: child.draft.screenshotsEnabled,
        screenshotsFrequency: child.draft.screenshotsFrequency,
        screenshotsResolution: child.draft.screenshotsResolution,
        showSuspensionActivity: child.draft.showSuspensionActivity,
        downtime: child.draft.downtime,
        keychains: child.draft.keychains.map(({ id, schedule }) => ({ id, schedule })),
        blockedApps: child.draft.blockedApps,
      }),
    {
      onSuccess: () => dispatch({ type: `childSaved` }),
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

  const newChildId = useMemo(() => uuid(), []);
  useEffect(() => {
    if (id === `new`) {
      dispatch({ type: `setChild`, child: empty.child(newChildId), new: true });
    }
  }, [id, newChildId]);

  if (id === `new`) {
    return <Navigate to={`/children/${newChildId}`} replace />;
  }

  if (deleteChild.state === `success`) {
    return <Navigate to="/children" />;
  }

  if (getChildQuery.isError) {
    return <ApiErrorMessage error={getChildQuery.error} />;
  }

  if (!state.child) {
    return <Loading />;
  }

  const { child, addingKeychain } = state;
  const { draft, original } = child;

  return (
    <EditChild
      isNew={state.child.isNew || false}
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
      computers={original.computers}
      iosDevices={original.iosDevices}
      deleteUser={deleteChild}
      startAddDevice={() => addDevice.mutate(id)}
      dismissAddDevice={() => addDevice.reset()}
      addDeviceRequest={ReqState.fromMutation(addDevice)}
      onStartTrial={() => startTrial.mutate(undefined)}
      downtime={draft.downtime ?? defaults.timeWindow()}
      downtimeEnabled={!!draft.downtime}
      setDowntimeEnabled={(enabled) => dispatch({ type: `setDowntimeEnabled`, enabled })}
      setDowntime={(downtime) => dispatch({ type: `setDowntime`, downtime })}
      deleteDevice={deleteComputerUser}
      saveButtonDisabled={
        !isDirty(state.child) || draft.name.trim() === `` || saveChild.isPending
      }
      onSave={() => saveChild.mutate(child)}
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
