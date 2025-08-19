import { convert, validate } from '@dash/block-rules';
import {
  BlockRuleEditor,
  EditBlockRules,
  Loading,
  PageHeading,
  TrashBtn,
} from '@dash/components';
import { ApiErrorMessage, ConfirmDeleteEntity } from '@dash/components';
import { Modal, SelectableListItem } from '@dash/components';
import { Result } from '@dash/types';
import { PlusIcon } from '@heroicons/react/24/solid';
import { Button, SelectMenu } from '@shared/components';
import { notNullish } from '@shared/ts-utils';
import isEqual from 'lodash.isequal';
import React, { useReducer } from 'react';
import { useParams } from 'react-router-dom';
import type { WebPolicy } from '@dash/types';
import Current from '../../environment';
import { Key, useConfirmableDelete, useMutation, useQuery } from '../../hooks';
import reducer from '../../reducers/ios-device-reducer';

const IOSDevice: React.FC = () => {
  const { deviceId: id = `` } = useParams<{ deviceId: string }>();
  const [state, dispatch] = useReducer(reducer, {
    enabledBlockGroups: [],
    webPolicyDomains: [],
    webPolicy: `blockAll`,
    newDomain: ``,
  });

  const deleteBlockRule = useConfirmableDelete(`blockRule`, {
    invalidating: [Key.iOSDevice(id)],
  });

  const saveBlockRule = useMutation(
    () => {
      const editingBlockRule = state.editingBlockRule;
      if (!editingBlockRule) return Result.resolveUnexpected(`fb05188d`);
      return Current.api.upsertBlockRule({
        id: editingBlockRule.id,
        deviceId: id,
        rule: convert.propsToBlockRule(editingBlockRule),
      });
    },
    {
      toast: `save:block-rule`,
      invalidating: [Key.iOSDevice(id)],
      onSuccess: () => dispatch({ type: `dismissBlockRule` }),
    },
  );

  const saveDevice = useMutation(
    () =>
      Current.api.updateIOSDevice({
        deviceId: id,
        enabledBlockGroups: state.enabledBlockGroups,
        webPolicy: state.webPolicy,
        webPolicyDomains: state.webPolicyDomains,
      }),
    { toast: `save:ios-device`, invalidating: [Key.iOSDevice(id)] },
  );

  const deviceQuery = useQuery(Key.iOSDevice(id), () => Current.api.getIOSDevice(id), {
    onReceive: (data) => dispatch({ type: `receiveData`, data }),
  });

  if (deviceQuery.isPending) {
    return <Loading />;
  }

  if (deviceQuery.isError) {
    return <ApiErrorMessage error={deviceQuery.error} />;
  }

  const isDirty =
    isEqual(state.enabledBlockGroups, deviceQuery.data.enabledBlockGroups) &&
    state.webPolicy === deviceQuery.data.webPolicy &&
    isEqual(state.webPolicyDomains, deviceQuery.data.webPolicyDomains);

  return (
    <div className="relative max-w-3xl">
      <PageHeading icon="phone">
        {deviceQuery.data.childName}'s {deviceQuery.data.deviceType}
      </PageHeading>
      <div className="mt-8">
        <div className="max-w-3xl">
          <div className="bg-white rounded-xl p-5 border-[0.5px] border-slate-200 shadow shadow-slate-300/50">
            <h2 className="text-lg font-bold text-slate-700 mb-4">Block Groups</h2>
            <div className="space-y-2">
              {deviceQuery.data.allBlockGroups.map(({ id, name }) => (
                <SelectableListItem
                  key={id}
                  title={name}
                  description={``}
                  selected={state.enabledBlockGroups.includes(id)}
                  onClick={() => dispatch({ type: `toggleBlockGroup`, id })}
                />
              ))}
            </div>
          </div>
        </div>
        <div className="mt-12 max-w-3xl">
          <h2 className="text-lg font-bold text-slate-700">Web Content Filter Policy</h2>
          <div className="bg-slate-100 mt-3 p-4 sm:p-6 rounded-xl relative">
            <SelectMenu
              options={WEB_POLICY_OPTIONS}
              selectedOption={state.webPolicy}
              setSelected={(policy) => dispatch({ type: `setWebPolicy`, policy })}
            />

            {(state.webPolicy === `blockAllExcept` ||
              state.webPolicy === `blockAdultAnd`) && (
              <div className="mt-5">
                <div className="flex justify-center items-center bg-white rounded-xl p-4 border-[0.5px] border-slate-200 shadow shadow-slate-300/50">
                  <div className="w-full">
                    <h3 className="font-medium text-slate-700 leading-tight mb-3">
                      {state.webPolicy === `blockAllExcept`
                        ? `Approved websites:`
                        : `Blocked websites:`}
                    </h3>
                    {state.webPolicyDomains.length > 0 && (
                      <div className="flex flex-col gap-2 mb-4">
                        {state.webPolicyDomains.map((domain: string) => (
                          <div
                            key={domain}
                            className="flex items-center justify-between bg-slate-100/80 rounded-lg pl-4 pr-3 py-2"
                          >
                            <span className="font-mono text-violet-700">{domain}</span>
                            <TrashBtn
                              onClick={() => dispatch({ type: `removeDomain`, domain })}
                            />
                          </div>
                        ))}
                      </div>
                    )}
                    <div className="flex gap-2">
                      <input
                        type="text"
                        className="flex-1 border border-slate-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-violet-300"
                        placeholder="Add domain (e.g. example.com)"
                        value={state.newDomain}
                        onChange={(e) =>
                          dispatch({ type: `setNewDomain`, value: e.target.value })
                        }
                        onKeyDown={(e) => {
                          if (e.key === `Enter`) {
                            e.preventDefault();
                            dispatch({ type: `addDomain` });
                          }
                        }}
                      />
                      <Button
                        type="button"
                        color="secondary"
                        className="flex items-center justify-center"
                        onClick={() => dispatch({ type: `addDomain` })}
                        disabled={
                          !state.newDomain.trim() ||
                          state.webPolicyDomains.includes(state.newDomain.trim())
                        }
                      >
                        <PlusIcon className="w-5 h-5 mr-2" />
                        Add domain
                      </Button>
                    </div>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
        {/* Block Rules */}
        <div className="mt-12 max-w-3xl mb-12">
          <h2 className="text-lg font-bold text-slate-700 mb-2">Block Rules</h2>
          <div className="bg-slate-100 mt-3 p-4 sm:p-6 rounded-xl">
            <EditBlockRules
              rules={deviceQuery.data.customBlockRules
                .map((rule) => {
                  const props = convert.blockRuleToProps(rule.rule);
                  if (!props) return null;
                  return [rule.id, props] satisfies [UUID, typeof props];
                })
                .filter(notNullish)}
              onDelete={deleteBlockRule.start}
              onEdit={(id) => {
                const rule = deviceQuery.data.customBlockRules.find((r) => r.id === id);
                if (rule) {
                  const props = convert.blockRuleToProps(rule.rule);
                  if (props) {
                    dispatch({ type: `setEditingBlockRule`, id, rule: props });
                  }
                }
              }}
              onAdd={() => dispatch({ type: `addBlockRule` })}
            />
          </div>
        </div>

        <div className="flex mt-8 justify-end border-slate-200 pt-8 border-t-2">
          <Button
            className="ScrollTop"
            type="button"
            disabled={isDirty || saveDevice.isPending}
            onClick={() => saveDevice.mutate(undefined)}
            color="primary"
          >
            Save settings
          </Button>
        </div>
      </div>
      <Modal
        icon="location"
        type="container"
        maximizeWidthForSmallScreens
        title={state.editingBlockRule?.id ? `Edit Block Rule` : `Create Block Rule`}
        isOpen={!!state.editingBlockRule}
        primaryButton={{
          label: state.editingBlockRule?.id ? `Save` : `Create`,
          action: () => {
            saveBlockRule.mutate(undefined);
          },
          disabled:
            !state.editingBlockRule ||
            !validate.blockRuleProps(state.editingBlockRule) ||
            saveBlockRule.isPending,
        }}
        secondaryButton={{ action: () => dispatch({ type: `dismissBlockRule` }) }}
      >
        {state.editingBlockRule && (
          <BlockRuleEditor
            {...state.editingBlockRule}
            emit={(event) => dispatch({ type: `editBlockRule`, event })}
          />
        )}
      </Modal>
      <ConfirmDeleteEntity type="block rule" action={deleteBlockRule} />
    </div>
  );
};

export default IOSDevice;

const WEB_POLICY_OPTIONS: { value: WebPolicy; display: string }[] = [
  { value: `blockAllExcept`, display: `Only approved websites` },
  { value: `blockAdultAnd`, display: `Blocklist plus limit adult websites` },
  { value: `blockAdult`, display: `Limit adult websites` },
  { value: `blockAll`, display: `Block everything` },
  { value: `allowAll`, display: `Unrestricted` },
] as const;
