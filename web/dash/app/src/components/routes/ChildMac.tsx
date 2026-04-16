import { ApiErrorMessage, ChildMacSettings, Loading } from '@dash/components';
import { type Child, defaults } from '@dash/types';
import React, { useReducer } from 'react';
import { useParams } from 'react-router-dom';
import type { RequestPublicKeychain } from '@dash/types';
import Current from '../../environment';
import { Key, useMutation, useQuery, useSelectableKeychains } from '../../hooks';
import ReqState from '../../lib/ReqState';
import { isDirty } from '../../lib/helpers';
import reducer from '../../reducers/user-reducer';

const ChildMacRoute: React.FC = () => {
  const { userId: id = `` } = useParams<{ userId: string }>();
  const [state, dispatch] = useReducer(reducer, {});
  const queryKey = Key.child(id);
  const getKeychains = useSelectableKeychains();

  const getChildQuery = useQuery(queryKey, () => Current.api.getChild(id), {
    onReceive: (child) => dispatch({ type: `setChild`, child }),
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
        filteringDisabled: child.draft.filteringDisabled,
        downtime: child.draft.downtime,
        keychains: child.draft.keychains.map(({ id, schedule }) => ({ id, schedule })),
        blockedApps: child.draft.blockedApps,
        alwaysBlockedGroupIds: [...child.draft.alwaysBlockedGroupIds],
        customAlwaysBlockedRules: child.draft.customAlwaysBlockedRules.map((r) => ({
          id: r.id,
          rule: r.rule,
          comment: r.comment,
        })),
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

  if (getChildQuery.isError) {
    return <ApiErrorMessage error={getChildQuery.error} />;
  }

  if (!state.child) {
    return <Loading />;
  }

  const { child, addingKeychain } = state;
  const { draft } = child;

  return (
    <ChildMacSettings
      childName={draft.name}
      hasConnectedMac={draft.computers.length > 0}
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
      filteringDisabled={draft.filteringDisabled}
      setFilteringDisabled={(disabled) =>
        dispatch({ type: `setFilteringDisabled`, disabled })
      }
      canDisableFilter={draft.canDisableFilter}
      downtime={draft.downtime ?? defaults.timeWindow()}
      downtimeEnabled={!!draft.downtime}
      setDowntimeEnabled={(enabled) => dispatch({ type: `setDowntimeEnabled`, enabled })}
      setDowntime={(downtime) => dispatch({ type: `setDowntime`, downtime })}
      keychains={draft.keychains}
      removeKeychain={(id) => dispatch({ type: `removeKeychain`, id })}
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
      startAddDevice={() => addDevice.mutate(id)}
      dismissAddDevice={() => addDevice.reset()}
      addDeviceRequest={ReqState.fromMutation(addDevice)}
      onStartTrial={() => startTrial.mutate(undefined)}
      saveButtonDisabled={!isDirty(state.child) || saveChild.isPending}
      onSave={() => saveChild.mutate(child)}
      supportsAlwaysBlocked={draft.supportsAlwaysBlocked}
      availableAlwaysBlockedGroups={draft.availableAlwaysBlockedGroups}
      alwaysBlockedGroupIds={draft.alwaysBlockedGroupIds}
      toggleAlwaysBlockedGroup={(id) =>
        dispatch({ type: `toggleAlwaysBlockedGroup`, id })
      }
      customAlwaysBlockedRules={draft.customAlwaysBlockedRules}
      editingAlwaysBlockedRule={state.editingAlwaysBlockedRule}
      addAlwaysBlockedRule={() => dispatch({ type: `addAlwaysBlockedRule` })}
      editAlwaysBlockedRule={(id, rule) =>
        dispatch({ type: `editAlwaysBlockedRule`, id, rule })
      }
      editAlwaysBlockedRuleForm={(event) =>
        dispatch({ type: `editAlwaysBlockedRuleForm`, event })
      }
      saveAlwaysBlockedRule={() => dispatch({ type: `saveAlwaysBlockedRule` })}
      dismissAlwaysBlockedRule={() => dispatch({ type: `dismissAlwaysBlockedRule` })}
      deleteAlwaysBlockedRule={(id) => dispatch({ type: `deleteAlwaysBlockedRule`, id })}
    />
  );
};

export default ChildMacRoute;
