import { convert, validate } from '@dash/block-rules';
import {
  AddKeychainDrawer,
  ApiErrorMessage,
  BlockGroupList,
  BlockRuleEditor,
  EditBlockRules,
  EmptyState,
  KeychainCard,
  Loading,
  Modal,
  PageHeading,
  TimeInput,
  ToggleCard,
} from '@dash/components';
import { defaults } from '@dash/types';
import { Button } from '@shared/components';
import cx from 'classnames';
import React, { useReducer } from 'react';
import { Link, Navigate, useParams } from 'react-router-dom';
import type { RequestPublicKeychain } from '@dash/types';
import Current from '../../environment';
import { Key, useMutation, useQuery, useSelectableKeychains } from '../../hooks';
import ReqState from '../../lib/ReqState';
import { isDirty } from '../../lib/helpers';
import reducer from '../../reducers/user-reducer';

const MacFilteringRoute: React.FC = () => {
  const { userId = `` } = useParams<{ userId: string }>();
  const [state, dispatch] = useReducer(reducer, {});
  const queryKey = Key.child(userId);
  const getKeychains = useSelectableKeychains();

  const childQuery = useQuery(queryKey, () => Current.api.getChild(userId), {
    onReceive: (child) => dispatch({ type: `setChild`, child }),
  });

  const saveChild = useMutation(
    () => {
      const child = state.child;
      if (!child) throw new Error(`No child loaded`);
      return Current.api.saveMacappFiltering({
        id: child.draft.id,
        filteringDisabled: child.draft.filteringDisabled,
        downtime: child.draft.downtime,
        keychains: child.draft.keychains.map(({ id, schedule }) => ({ id, schedule })),
        alwaysBlockedGroupIds: [...child.draft.alwaysBlockedGroupIds],
        customAlwaysBlockedRules: child.draft.customAlwaysBlockedRules.map((r) => ({
          id: r.id,
          rule: r.rule,
          comment: r.comment,
        })),
      });
    },
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

  if (childQuery.isError) {
    return <ApiErrorMessage error={childQuery.error} />;
  }

  if (!state.child) {
    return <Loading />;
  }

  if (state.child.original.computers.length === 0) {
    return <Navigate to=".." replace relative="path" />;
  }

  const { draft } = state.child;
  const { addingKeychain, editingAlwaysBlockedRule } = state;
  const downtimeWindow = draft.downtime ?? defaults.timeWindow();
  const downtimeEnabled = !!draft.downtime;
  const saveDisabled = !isDirty(state.child) || saveChild.isPending;

  return (
    <div className="max-w-3xl">
      <AddKeychainDrawer
        request={
          addingKeychain === undefined ? undefined : ReqState.fromQuery(getKeychains)
        }
        onSelect={(keychain) =>
          dispatch({
            type: `setAddingKeychain`,
            keychain: addingKeychain?.id === keychain.id ? null : keychain,
          })
        }
        onDismiss={() => dispatch({ type: `setAddingKeychain`, keychain: undefined })}
        onConfirm={() => {
          if (addingKeychain) {
            dispatch({ type: `addKeychain`, keychain: addingKeychain });
          }
          dispatch({ type: `setAddingKeychain`, keychain: undefined });
        }}
        selected={addingKeychain ?? undefined}
        existingKeychains={draft.keychains}
        userName={draft.name}
        schedule={addingKeychain?.schedule}
        setSchedule={(schedule) =>
          dispatch({ type: `setAddingKeychainSchedule`, schedule })
        }
        onRequestPublicKeychain={(searchQuery, description) =>
          requestPublicKeychain.mutate({ searchQuery, description })
        }
        requestPublicKeychainRequest={ReqState.fromMutation(requestPublicKeychain)}
      />

      <Link
        to=".."
        relative="path"
        className="inline-flex items-center text-sm text-violet-600 hover:underline mb-4"
      >
        <i className="fa-solid fa-arrow-left mr-1.5" />
        {draft.name}&rsquo;s Mac
      </Link>
      <PageHeading icon="shield">Internet filtering</PageHeading>

      <div className="mt-8">
        <h2 className="text-lg font-bold text-slate-700">Downtime</h2>
        <ToggleCard
          title="Enable downtime"
          description="Completely restrict all internet access during specified hours"
          enabled={downtimeEnabled}
          setEnabled={(enabled) => dispatch({ type: `setDowntimeEnabled`, enabled })}
        >
          <div
            className={cx(
              `flex justify-center items-center mt-4 bg-white rounded-xl p-4 gap-4 flex-col sm:flex-row md:flex-col md+:flex-row border-[0.5px] border-slate-200 shadow shadow-slate-300/50`,
              downtimeEnabled || `hidden`,
            )}
          >
            <span className="text-slate-500 font-medium">From</span>
            <TimeInput
              time={downtimeWindow.start}
              setTime={(start) =>
                dispatch({ type: `setDowntime`, downtime: { ...downtimeWindow, start } })
              }
            />
            <span className="text-slate-500 font-medium">to</span>
            <TimeInput
              time={downtimeWindow.end}
              setTime={(end) =>
                dispatch({ type: `setDowntime`, downtime: { ...downtimeWindow, end } })
              }
            />
          </div>
        </ToggleCard>
      </div>

      {draft.supportsAlwaysBlocked && (
        <div className="mt-12">
          <h2 className="text-lg font-bold text-slate-700 mb-1">Always-Blocked</h2>
          <p className="text-slate-500 text-sm mb-4">
            These blocks apply at all times, even when the filter is suspended.
          </p>
          {draft.availableAlwaysBlockedGroups.length > 0 && (
            <BlockGroupList
              title="Always-Blocked groups"
              groups={draft.availableAlwaysBlockedGroups}
              enabledGroupIds={draft.alwaysBlockedGroupIds}
              onToggle={(id) => dispatch({ type: `toggleAlwaysBlockedGroup`, id })}
            />
          )}
          <div className={cx(draft.availableAlwaysBlockedGroups.length > 0 && `mt-6`)}>
            <h3 className="text-base font-bold text-slate-700 mb-3">
              Custom Always-Blocked rules
            </h3>
            <div className="bg-white rounded-xl p-5 border-[0.5px] border-slate-200 shadow shadow-slate-300/50">
              <EditBlockRules
                rules={draft.customAlwaysBlockedRules
                  .map((r) => {
                    const props = convert.blockRuleToProps(r.rule);
                    if (!props) return null;
                    return {
                      id: r.id,
                      props,
                      readOnly: r.rule.case !== `hostnameOrSubdomain`,
                    };
                  })
                  .filter((r) => r !== null)}
                onAdd={() => dispatch({ type: `addAlwaysBlockedRule` })}
                onEdit={(id) => {
                  const entry = draft.customAlwaysBlockedRules.find((r) => r.id === id);
                  if (!entry) return;
                  if (entry.rule.case !== `hostnameOrSubdomain`) return;
                  const props = convert.blockRuleToProps(entry.rule);
                  if (props) dispatch({ type: `editAlwaysBlockedRule`, id, rule: props });
                }}
                onDelete={(id) => dispatch({ type: `deleteAlwaysBlockedRule`, id })}
              />
            </div>
          </div>
        </div>
      )}

      <div className="mt-12">
        <h2 className="text-lg font-bold text-slate-700">Filtering</h2>
        {draft.canDisableFilter && (
          <ToggleCard
            title="Filter internet access"
            description="Block all internet access except sites allowed by assigned keychains"
            enabled={!draft.filteringDisabled}
            setEnabled={(enabled) =>
              dispatch({ type: `setFilteringDisabled`, disabled: !enabled })
            }
            disabledReason={
              !draft.screenshotsEnabled
                ? `Internet filtering can only be disabled when screenshots are enabled`
                : undefined
            }
            warning={
              draft.filteringDisabled
                ? `${draft.name} has unrestricted internet access and is only protected by ${draft.keyloggingEnabled ? `screenshots and keylogging` : `screenshots`}`
                : undefined
            }
          />
        )}
        {!draft.filteringDisabled && (
          <div className="mt-4 flex flex-col space-y-4">
            {draft.keychains.length === 0 ? (
              <EmptyState
                heading="No keychains"
                secondaryText="By default, all internet access is blocked for this child until you assign a keychain."
                icon="key"
                buttonText="Add keychain"
                action={() => dispatch({ type: `setAddingKeychain`, keychain: null })}
              />
            ) : (
              <>
                {draft.keychains.map((keychain) => (
                  <KeychainCard
                    mode="assigned_to_child"
                    keychainId={keychain.id}
                    schedule={keychain.schedule}
                    key={keychain.id}
                    name={keychain.name}
                    description={keychain.description}
                    numKeys={keychain.numKeys}
                    isPublic={keychain.isPublic}
                    onRemove={() => dispatch({ type: `removeKeychain`, id: keychain.id })}
                    setSchedule={(schedule) =>
                      dispatch({
                        type: `setKeychainSchedule`,
                        id: keychain.id,
                        schedule,
                      })
                    }
                  />
                ))}
                <Button
                  type="button"
                  onClick={() => dispatch({ type: `setAddingKeychain`, keychain: null })}
                  color="secondary"
                  className="xs:self-end"
                >
                  <i className="fa fa-plus mr-2" />
                  Add keychain
                </Button>
              </>
            )}
          </div>
        )}
      </div>

      <div className="flex mt-12 pt-8 border-t-2 border-slate-200 justify-end">
        <Button
          type="button"
          disabled={saveDisabled}
          onClick={() => saveChild.mutate(undefined)}
          color="primary"
        >
          Save settings
        </Button>
      </div>

      <Modal
        icon="shield"
        type="container"
        maximizeWidthForSmallScreens
        title={editingAlwaysBlockedRule?.id ? `Edit Block Rule` : `Create Block Rule`}
        isOpen={!!editingAlwaysBlockedRule}
        primaryButton={{
          type: `action`,
          label: editingAlwaysBlockedRule?.id ? `Save` : `Create`,
          action: () => dispatch({ type: `saveAlwaysBlockedRule` }),
          disabled:
            !editingAlwaysBlockedRule ||
            !validate.blockRuleProps(editingAlwaysBlockedRule),
        }}
        secondaryButton={{
          type: `action`,
          action: () => dispatch({ type: `dismissAlwaysBlockedRule` }),
        }}
      >
        {editingAlwaysBlockedRule && (
          <BlockRuleEditor
            {...editingAlwaysBlockedRule}
            addressOnly
            emit={(event) => dispatch({ type: `editAlwaysBlockedRuleForm`, event })}
          />
        )}
      </Modal>
    </div>
  );
};

export default MacFilteringRoute;
