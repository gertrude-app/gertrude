// import { convert, validate } from '@dash/block-rules';
import {
  ApiErrorMessage,
  /*ConfirmDeleteEntity*/
  AppHeader,
  BetaBadge,
  BlockGroupList,
  Loading,
  PageHeading,
  // EditBlockRules,
  PlanTeaser,
  // BlockRuleEditor,
  PodcastsDeviceSection,
  ToggleCard,
  TrashBtn,
} from '@dash/components';
// import { PlusIcon } from '@heroicons/react/24/solid';
import { Button /* SelectMenu */ } from '@shared/components';
// import { Result } from '@shared/pairql';
// import { notNullish } from '@shared/ts-utils';
import isEqual from 'lodash.isequal';
import React, { useReducer } from 'react';
import { useParams } from 'react-router-dom';
// import type { WebPolicy } from '@dash/types';
import type { PodcastsRunwayTier } from '../../podcastsSubscriptionRunway';
import type { PodcastsStatus } from '@dash/components';
import Current from '../../environment';
import { Key, /*useConfirmableDelete, */ useMutation, useQuery } from '../../hooks';
import {
  EMPTY_EXTENDED,
  extendedControlsPayload,
  normalizeExtended,
} from '../../lib/extendedRestrictions';
import { podcastsSubscriptionRunway } from '../../podcastsSubscriptionRunway';
import reducer from '../../reducers/ios-device-reducer';
import ExtendedRestrictions from './ExtendedRestrictions';
import MusicCuration from './MusicCuration';

const TIER_TO_STATUS: Record<PodcastsRunwayTier, PodcastsStatus> = {
  active: `active`,
  expiring: `approaching`,
  lapsed: `paused`,
};

const IOSDevice: React.FC = () => {
  const { userId: childId = ``, deviceId: id = `` } = useParams<{
    userId: string;
    deviceId: string;
  }>();
  const [state, dispatch] = useReducer(reducer, {
    enabledBlockGroups: [],
    webPolicyDomains: [],
    webPolicy: `blockAll`,
    newDomain: ``,
    isProfileLocked: true,
    allowAppRemoval: false,
    allowEraseContentAndSettings: false,
    allowAppInstallation: true,
    hasExtendedControls: false,
    whitelistedAppBundleIds: null,
    newBundleId: ``,
    webAllowList: null,
    newBookmarkUrl: ``,
    newBookmarkTitle: ``,
    extended: EMPTY_EXTENDED,
  });

  // const deleteBlockRule = useConfirmableDelete(`blockRule`, {
  //   invalidating: [Key.iOSDevice(id)],
  // });

  // const saveBlockRule = useMutation(
  //   () => {
  //     const editingBlockRule = state.editingBlockRule;
  //     if (!editingBlockRule) return Result.resolveUnexpected(`fb05188d`);
  //     return Current.api.upsertBlockRule({
  //       id: editingBlockRule.id,
  //       deviceId: id,
  //       rule: convert.propsToBlockRule(editingBlockRule),
  //     });
  //   },
  //   {
  //     toast: `save:block-rule`,
  //     invalidating: [Key.iOSDevice(id)],
  //     onSuccess: () => dispatch({ type: `dismissBlockRule` }),
  //   },
  // );

  const saveDevice = useMutation(
    async () => {
      const result = await Current.api.updateIOSDevice({
        deviceId: id,
        enabledBlockGroups: [...state.enabledBlockGroups],
        webPolicy: state.webPolicy,
        webPolicyDomains: [...state.webPolicyDomains],
        isProfileLocked: state.isProfileLocked,
        allowAppRemoval: state.allowAppRemoval,
        allowEraseContentAndSettings: state.allowEraseContentAndSettings,
        allowAppInstallation: state.allowAppInstallation,
      });
      if (result.isError || !state.hasExtendedControls) {
        return result;
      }
      return Current.api.saveExtendedSupervisionControls({
        deviceId: id,
        controls: {
          whitelistedAppBundleIds: state.whitelistedAppBundleIds
            ? [...state.whitelistedAppBundleIds]
            : undefined,
          webAllowList: state.webAllowList
            ? state.webAllowList.map((b) => ({ ...b }))
            : undefined,
          ...extendedControlsPayload(state.extended),
        },
      });
    },
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

  const dt = deviceQuery.data.deviceType;
  const blocker = deviceQuery.data.blocker;
  const am = deviceQuery.data.am;
  const music = deviceQuery.data.music;
  const podcastsRunway = am ? podcastsSubscriptionRunway(am.subscription) : undefined;

  const requestPinCode = async (): Promise<number | null> => {
    const result = await Current.api.requestAmPinReset({ deviceId: id });
    return result.isError ? null : (result.value?.code ?? null);
  };

  const isDirty = blocker
    ? isEqual(state.enabledBlockGroups, blocker.enabledBlockGroups) &&
      state.webPolicy === blocker.webPolicy &&
      isEqual(state.webPolicyDomains, blocker.webPolicyDomains) &&
      state.isProfileLocked === blocker.isProfileLocked &&
      state.allowAppRemoval === blocker.allowAppRemoval &&
      state.allowEraseContentAndSettings === blocker.allowEraseContentAndSettings &&
      state.allowAppInstallation === blocker.allowAppInstallation &&
      isEqual(
        state.whitelistedAppBundleIds,
        blocker.extendedSupervisionControls?.whitelistedAppBundleIds ?? null,
      ) &&
      isEqual(
        state.webAllowList,
        blocker.extendedSupervisionControls?.webAllowList ?? null,
      ) &&
      isEqual(state.extended, normalizeExtended(blocker.extendedSupervisionControls))
    : true;

  return (
    <div className="relative max-w-3xl">
      <PageHeading icon="phone">
        {deviceQuery.data.childName}'s {deviceQuery.data.deviceType}
      </PageHeading>
      <div className="mt-8 space-y-16">
        {am && podcastsRunway && (
          <PodcastsDeviceSection
            status={TIER_TO_STATUS[podcastsRunway.tier]}
            childName={deviceQuery.data.childName}
            deviceType={dt}
            accessEndsAt={podcastsRunway.accessEndsAt}
            trialDaysRemaining={podcastsRunway.trialDaysRemaining}
            requestPinCode={requestPinCode}
          />
        )}
        {deviceQuery.data.musicConnected && (
          <MusicDeviceSection
            childId={childId}
            childName={deviceQuery.data.childName}
            requiresPayment={music?.requiresPayment ?? false}
          />
        )}
        {blocker && (
          <div className="max-w-3xl">
            <AppHeader app="blocker" />
            <div className="mt-6">
              <BlockGroupList
                groups={blocker.allBlockGroups}
                enabledGroupIds={state.enabledBlockGroups}
                onToggle={(id) => dispatch({ type: `toggleBlockGroup`, id })}
              />
            </div>
            {blocker.isSupervised && (
              <div className="mt-12 max-w-3xl">
                <h2 className="text-lg font-bold text-slate-700">
                  Supervision Profile Settings
                </h2>
                <div className="mt-2 mb-4 flex items-start gap-3 rounded-xl bg-amber-50 border border-amber-200 px-4 py-3 text-sm text-amber-800">
                  <i className="fa-solid fa-circle-info text-amber-500 mt-0.5 shrink-0" />
                  <span>
                    After changing any setting below, you&rsquo;ll need to sync the
                    profile on the {dt} by opening the Gertrude app and going to{` `}
                    <b>Info &rarr; Sync Profile</b>.
                  </span>
                </div>
                <ToggleCard
                  title="Prevent protection removal"
                  description={`Make it impossible for the ${dt} user to remove Gertrude’s protection.`}
                  enabled={state.isProfileLocked}
                  setEnabled={(v) => dispatch({ type: `setIsProfileLocked`, value: v })}
                  warning={
                    !state.isProfileLocked
                      ? `The ${dt} user may remove the profile in order to stop Gertrude’s protection and uninstall.`
                      : undefined
                  }
                />
                <ToggleCard
                  title="Allow deleting apps"
                  description={`Keeping this off prevents the ${dt} user from deleting the Gertrude app, but also prevents them from deleting any app. Enable temporarily if you need to delete some apps from the ${dt}, then re-enable.`}
                  enabled={state.allowAppRemoval}
                  setEnabled={(v) => dispatch({ type: `setAllowAppRemoval`, value: v })}
                  warning={
                    state.allowAppRemoval
                      ? `The user can delete apps (including Gertrude) from their ${dt}`
                      : undefined
                  }
                />
                <ToggleCard
                  title="Allow factory reset"
                  description={`Allow the ${dt} to be erased and reset to factory settings, bypassing protection.`}
                  enabled={state.allowEraseContentAndSettings}
                  setEnabled={(v) =>
                    dispatch({ type: `setAllowEraseContentAndSettings`, value: v })
                  }
                  warning={
                    state.allowEraseContentAndSettings
                      ? `The user will be able to erase the ${dt} removing Gertrude and all restrictions`
                      : undefined
                  }
                />
                <ToggleCard
                  title="Allow installing apps"
                  description={`Allow the ${dt} user to install new apps from the App Store. Turn this off to remove the App Store icon entirely and block app installation.`}
                  enabled={state.allowAppInstallation}
                  setEnabled={(v) =>
                    dispatch({ type: `setAllowAppInstallation`, value: v })
                  }
                />
                {blocker.extendedSupervisionControls !== undefined && (
                  <div className="mt-10 pt-8 border-t-2 border-slate-100">
                    <h3 className="text-lg font-bold text-slate-700">
                      Extended controls
                    </h3>
                    <p className="text-sm text-slate-500 mt-1">
                      Fine-grained restrictions for this supervised {dt}. Anything you
                      turn on (purple) is enforced on the device; anything left off stays
                      available.
                    </p>
                    <ToggleCard
                      title="Only allow approved apps"
                      description={`Hide every app on the ${dt} except the ones you specifically approve.`}
                      enabled={state.whitelistedAppBundleIds !== null}
                      setEnabled={(v) =>
                        dispatch({ type: `setAppWhitelistEnabled`, value: v })
                      }
                      warning={
                        state.whitelistedAppBundleIds?.length === 0
                          ? `With no apps approved, nearly every app will be hidden from the ${dt}.`
                          : undefined
                      }
                    >
                      {state.whitelistedAppBundleIds !== null && (
                        <div className="mt-4">
                          {state.whitelistedAppBundleIds.length > 0 && (
                            <div className="flex flex-col gap-2 mb-4">
                              {state.whitelistedAppBundleIds.map((bundleId) => (
                                <div
                                  key={bundleId}
                                  className="flex items-center justify-between bg-white rounded-lg pl-4 pr-3 py-2"
                                >
                                  <span className="font-mono text-sm text-violet-700">
                                    {bundleId}
                                  </span>
                                  <TrashBtn
                                    onClick={() =>
                                      dispatch({ type: `removeBundleId`, bundleId })
                                    }
                                  />
                                </div>
                              ))}
                            </div>
                          )}
                          <div className="flex gap-2">
                            <input
                              type="text"
                              className="flex-1 border border-slate-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-violet-300"
                              placeholder="App bundle ID (e.g. com.apple.mobilesafari)"
                              value={state.newBundleId}
                              onChange={(e) =>
                                dispatch({
                                  type: `setNewBundleId`,
                                  value: e.target.value,
                                })
                              }
                              onKeyDown={(e) => {
                                if (e.key === `Enter`) {
                                  e.preventDefault();
                                  dispatch({ type: `addBundleId` });
                                }
                              }}
                            />
                            <Button
                              type="button"
                              color="secondary"
                              onClick={() => dispatch({ type: `addBundleId` })}
                              disabled={
                                !state.newBundleId.trim() ||
                                state.whitelistedAppBundleIds.includes(
                                  state.newBundleId.trim(),
                                )
                              }
                            >
                              Add app
                            </Button>
                          </div>
                        </div>
                      )}
                    </ToggleCard>
                    <ToggleCard
                      title="Only allow approved websites"
                      description={`Block every website on the ${dt} except the ones you specifically approve.`}
                      enabled={state.webAllowList !== null}
                      setEnabled={(v) =>
                        dispatch({ type: `setWebAllowListEnabled`, value: v })
                      }
                      warning={
                        state.webAllowList?.length === 0
                          ? `With no websites approved, the entire web will be blocked on the ${dt}.`
                          : undefined
                      }
                    >
                      {state.webAllowList !== null && (
                        <div className="mt-4">
                          {state.webAllowList.length > 0 && (
                            <div className="flex flex-col gap-2 mb-4">
                              {state.webAllowList.map((bookmark) => (
                                <div
                                  key={bookmark.url}
                                  className="flex items-center justify-between bg-white rounded-lg pl-4 pr-3 py-2"
                                >
                                  <div className="min-w-0">
                                    <span className="block font-medium text-slate-700">
                                      {bookmark.title}
                                    </span>
                                    <span className="block font-mono text-sm text-violet-700 truncate">
                                      {bookmark.url}
                                    </span>
                                  </div>
                                  <TrashBtn
                                    onClick={() =>
                                      dispatch({
                                        type: `removeBookmark`,
                                        url: bookmark.url,
                                      })
                                    }
                                  />
                                </div>
                              ))}
                            </div>
                          )}
                          <div className="flex flex-col sm:flex-row gap-2">
                            <input
                              type="text"
                              className="sm:w-44 border border-slate-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-violet-300"
                              placeholder="Name (e.g. Weather)"
                              value={state.newBookmarkTitle}
                              onChange={(e) =>
                                dispatch({
                                  type: `setNewBookmarkTitle`,
                                  value: e.target.value,
                                })
                              }
                            />
                            <input
                              type="text"
                              className="flex-1 border border-slate-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-violet-300"
                              placeholder="URL (e.g. https://weather.com)"
                              value={state.newBookmarkUrl}
                              onChange={(e) =>
                                dispatch({
                                  type: `setNewBookmarkUrl`,
                                  value: e.target.value,
                                })
                              }
                              onKeyDown={(e) => {
                                if (e.key === `Enter`) {
                                  e.preventDefault();
                                  dispatch({ type: `addBookmark` });
                                }
                              }}
                            />
                            <Button
                              type="button"
                              color="secondary"
                              onClick={() => dispatch({ type: `addBookmark` })}
                              disabled={
                                !state.newBookmarkTitle.trim() ||
                                !state.newBookmarkUrl.trim() ||
                                state.webAllowList.some(
                                  (b) => b.url === state.newBookmarkUrl.trim(),
                                )
                              }
                            >
                              Add website
                            </Button>
                          </div>
                        </div>
                      )}
                    </ToggleCard>
                    <ExtendedRestrictions extended={state.extended} dispatch={dispatch} />
                  </div>
                )}
              </div>
            )}
            {/* <div className="mt-12 max-w-3xl">
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
        </div> */}
            {/* <div className="mt-12 max-w-3xl mb-12">
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
        </div> */}

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
        )}
      </div>
      {/* <Modal
        icon="location"
        type="container"
        maximizeWidthForSmallScreens
        title={state.editingBlockRule?.id ? `Edit Block Rule` : `Create Block Rule`}
        isOpen={!!state.editingBlockRule}
        primaryButton={{
          type: `action`,
          label: state.editingBlockRule?.id ? `Save` : `Create`,
          action: () => {
            saveBlockRule.mutate(undefined);
          },
          disabled:
            !state.editingBlockRule ||
            !validate.blockRuleProps(state.editingBlockRule) ||
            saveBlockRule.isPending,
        }}
        secondaryButton={{
          type: `action`,
          action: () => dispatch({ type: `dismissBlockRule` }),
        }}
      >
        {state.editingBlockRule && (
          <BlockRuleEditor
            {...state.editingBlockRule}
            emit={(event) => dispatch({ type: `editBlockRule`, event })}
          />
        )}
      </Modal>
      <ConfirmDeleteEntity type="block rule" action={deleteBlockRule} /> */}
    </div>
  );
};

const MusicDeviceSection: React.FC<{
  childId: string;
  childName: string;
  requiresPayment: boolean;
}> = ({ childId, childName, requiresPayment }) => (
  <div className="max-w-3xl">
    <AppHeader app="music">
      <BetaBadge />
    </AppHeader>
    {requiresPayment ? (
      <div className="mt-4">
        <p className="text-slate-500 mb-4">
          Paused — your Gertrude account needs the Medium plan (or Full) to manage
          Gertrude Music.
        </p>
        <PlanTeaser
          className="mb-4"
          plan="medium"
          extraBullets={[`Includes Gertrude Music for approved Apple Music albums`]}
        />
        <Button type="link" to="/settings" color="primary" size="small">
          Manage subscription
        </Button>
      </div>
    ) : (
      <MusicCuration childId={childId} childName={childName} className="mt-6" />
    )}
  </div>
);

export default IOSDevice;

// const WEB_POLICY_OPTIONS: { value: WebPolicy; display: string }[] = [
//   { value: `blockAllExcept`, display: `Only approved websites` },
//   { value: `blockAdultAnd`, display: `Blocklist plus limit adult websites` },
//   { value: `blockAdult`, display: `Limit adult websites` },
//   { value: `blockAll`, display: `Block everything` },
//   { value: `allowAll`, display: `Unrestricted` },
// ] as const;
