import { convert, validate } from '@dash/block-rules';
import { NoSymbolIcon } from '@heroicons/react/24/outline';
import { Button, TextInput } from '@shared/components';
import { posessive } from '@shared/string';
import cx from 'classnames';
import React from 'react';
import { Link } from 'react-router-dom';
import type { EditBlockRuleProps, EditEvent } from '@dash/block-rules';
import type {
  BlockRule,
  BlockedMacApp,
  MacAppConnectionCode,
  PlainTimeWindow,
  RequestState,
  RuleSchedule,
  SuccessOutput,
  UserKeychainSummary as Keychain,
} from '@dash/types';
import EmptyState from '../EmptyState';
import TimeInput from '../Forms/TimeInput';
import ToggleCard from '../Forms/ToggleCard';
import KeychainCard from '../Keychains/KeychainCard';
import Modal from '../Modal/Modal';
import PageHeading from '../PageHeading';
import BlockGroupList from '../iOS/BlockGroupList';
import BlockRuleEditor from '../iOS/BlockRuleEditor';
import EditBlockRules from '../iOS/EditBlockRules';
import AddKeychainDrawer from './AddKeychainDrawer';
import BlockedAppCard from './BlockedAppCard';
import ConnectDeviceModal from './ConnectDeviceModal';

interface Props {
  childName: string;
  hasConnectedMac: boolean;
  keyloggingEnabled: boolean;
  setKeyloggingEnabled(enabled: boolean): unknown;
  screenshotsEnabled: boolean;
  setScreenshotsEnabled(enabled: boolean): unknown;
  screenshotsResolution: number;
  setScreenshotsResolution(resolution: number): unknown;
  screenshotsFrequency: number;
  setScreenshotsFrequency(frequency: number): unknown;
  showSuspensionActivity: boolean;
  setShowSuspensionActivity(show: boolean): unknown;
  filteringDisabled: boolean;
  setFilteringDisabled(disabled: boolean): unknown;
  canDisableFilter: boolean;
  downtimeEnabled: boolean;
  setDowntimeEnabled(enabled: boolean): unknown;
  downtime: PlainTimeWindow;
  setDowntime(window: PlainTimeWindow): unknown;
  keychains: Keychain[];
  removeKeychain(id: UUID): unknown;
  onAddKeychainClicked(): unknown;
  onSelectKeychainToAdd(keychain: Keychain): unknown;
  onConfirmAddKeychain(): unknown;
  onDismissAddKeychain(): unknown;
  addingKeychain?: Keychain | null;
  fetchSelectableKeychainsRequest?: RequestState<{ own: Keychain[]; public: Keychain[] }>;
  keychainSchedule?: RuleSchedule;
  setAddingKeychainSchedule(schedule?: RuleSchedule): unknown;
  setAssignedKeychainSchedule(id: UUID, schedule?: RuleSchedule): unknown;
  blockedApps?: BlockedMacApp[];
  installedApps?: Array<{ bundleId: string; name: string; iconUrl?: string }>;
  newBlockedAppIdentifier: string;
  updateNewBlockedAppIdentifier(identifier: string): unknown;
  addNewBlockedApp(): unknown;
  removeBlockedApp(id: UUID): unknown;
  setBlockedAppSchedule(id: UUID, schedule?: RuleSchedule): unknown;
  onRequestPublicKeychain(searchQuery: string, description: string): unknown;
  requestPublicKeychainRequest: RequestState<SuccessOutput>;
  startAddDevice(): unknown;
  dismissAddDevice(): unknown;
  addDeviceRequest?: RequestState<MacAppConnectionCode.Output>;
  onStartTrial(): unknown;
  saveButtonDisabled: boolean;
  onSave(): unknown;
  supportsAlwaysBlocked: boolean;
  availableAlwaysBlockedGroups: Array<{
    id: UUID;
    name: string;
    description: string;
    longDescription: string;
  }>;
  alwaysBlockedGroupIds: UUID[];
  toggleAlwaysBlockedGroup(id: UUID): unknown;
  customAlwaysBlockedRules: Array<{ id: UUID; rule: BlockRule; comment?: string }>;
  editingAlwaysBlockedRule?: EditBlockRuleProps & { id?: UUID };
  addAlwaysBlockedRule(): unknown;
  editAlwaysBlockedRule(id: UUID, rule: EditBlockRuleProps): unknown;
  editAlwaysBlockedRuleForm(event: EditEvent): unknown;
  saveAlwaysBlockedRule(): unknown;
  dismissAlwaysBlockedRule(): unknown;
  deleteAlwaysBlockedRule(id: UUID): unknown;
}

const ChildMacSettingsLegacy: React.FC<Props> = ({
  childName,
  hasConnectedMac,
  keyloggingEnabled,
  setKeyloggingEnabled,
  screenshotsEnabled,
  setScreenshotsEnabled,
  screenshotsResolution,
  setScreenshotsResolution,
  screenshotsFrequency,
  setScreenshotsFrequency,
  showSuspensionActivity,
  setShowSuspensionActivity,
  filteringDisabled,
  setFilteringDisabled,
  canDisableFilter,
  downtimeEnabled,
  setDowntimeEnabled,
  downtime,
  setDowntime,
  keychains,
  removeKeychain,
  onAddKeychainClicked,
  onSelectKeychainToAdd,
  onConfirmAddKeychain,
  onDismissAddKeychain,
  addingKeychain,
  fetchSelectableKeychainsRequest,
  keychainSchedule,
  setAddingKeychainSchedule,
  setAssignedKeychainSchedule,
  blockedApps,
  installedApps,
  newBlockedAppIdentifier,
  updateNewBlockedAppIdentifier,
  addNewBlockedApp,
  removeBlockedApp,
  setBlockedAppSchedule,
  onRequestPublicKeychain,
  requestPublicKeychainRequest,
  startAddDevice,
  dismissAddDevice,
  addDeviceRequest,
  onStartTrial,
  saveButtonDisabled,
  onSave,
  supportsAlwaysBlocked,
  availableAlwaysBlockedGroups,
  alwaysBlockedGroupIds,
  toggleAlwaysBlockedGroup,
  customAlwaysBlockedRules,
  editingAlwaysBlockedRule,
  addAlwaysBlockedRule,
  editAlwaysBlockedRule,
  editAlwaysBlockedRuleForm,
  saveAlwaysBlockedRule,
  dismissAlwaysBlockedRule,
  deleteAlwaysBlockedRule,
}) => (
  <div className="relative max-w-3xl">
    <AddKeychainDrawer
      request={fetchSelectableKeychainsRequest}
      onSelect={onSelectKeychainToAdd}
      onDismiss={onDismissAddKeychain}
      onConfirm={onConfirmAddKeychain}
      selected={addingKeychain ?? undefined}
      existingKeychains={keychains}
      userName={childName}
      schedule={keychainSchedule}
      setSchedule={setAddingKeychainSchedule}
      onRequestPublicKeychain={onRequestPublicKeychain}
      requestPublicKeychainRequest={requestPublicKeychainRequest}
    />
    <PageHeading icon="laptop">{posessive(childName)} Mac Settings</PageHeading>

    <ConnectDeviceModal
      request={addDeviceRequest}
      dismissAddDevice={dismissAddDevice}
      onStartTrial={onStartTrial}
    />

    {!hasConnectedMac ? (
      <EmptyState
        heading="No Mac computers connected"
        secondaryText={
          <>
            {childName} doesn't have any Mac computers connected yet. To get started,
            download the Mac app from{` `}
            <a
              href="https://gertrude.app/download"
              className="font-mono text-violet-600 hover:underline"
              target="_blank"
              rel="noreferrer"
            >
              https://gertrude.app/download
            </a>
            {` `}
            on the Mac your child uses, then get a connection code to connect it.
          </>
        }
        icon="laptop"
        buttonText="Get connection code"
        buttonIcon="desktop"
        action={startAddDevice}
        className="mt-8"
      />
    ) : (
      <>
        <div className="mt-8 max-w-3xl">
          <h2 className="text-lg font-bold text-slate-700">Monitoring</h2>
          <ToggleCard
            title="Enable keylogging"
            description="Sends reports of all keystrokes to your review"
            enabled={keyloggingEnabled}
            setEnabled={setKeyloggingEnabled}
          />
          <ToggleCard
            title="Enable screenshots"
            description="Periodically take a screenshot and upload for your review"
            enabled={screenshotsEnabled}
            setEnabled={setScreenshotsEnabled}
            disabledReason={
              filteringDisabled
                ? `Screenshots are required when internet filtering is disabled`
                : undefined
            }
          >
            <div
              className={cx(
                `flex flex-col space-y-3 md:flex-row md:space-x-3 md:space-y-0 mt-5`,
                screenshotsEnabled || `hidden`,
              )}
            >
              <TextInput
                type="positiveInteger"
                label="Resolution"
                value={String(screenshotsResolution)}
                setValue={(num) => setScreenshotsResolution(Number(num))}
                unit="pixels"
              />
              <TextInput
                type="positiveInteger"
                label="Frequency"
                value={String(screenshotsFrequency)}
                setValue={(num) => setScreenshotsFrequency(Number(num))}
                unit="seconds"
              />
            </div>
          </ToggleCard>
          <ToggleCard
            title="Emphasize filter suspension activity"
            description="Visually highlight activity that is recorded while filter is suspended"
            enabled={showSuspensionActivity}
            setEnabled={setShowSuspensionActivity}
            className={cx(
              `transition-opacity duration-300`,
              !(screenshotsEnabled || keyloggingEnabled) && `!hidden`,
            )}
          />
        </div>

        <div className="mt-12 max-w-3xl">
          <h2 className="text-lg font-bold text-slate-700">Downtime</h2>
          <ToggleCard
            title="Enable downtime"
            description="Completely restrict all internet access during specified hours"
            enabled={downtimeEnabled}
            setEnabled={setDowntimeEnabled}
          >
            <div
              className={cx(
                `flex justify-center items-center mt-4 bg-white rounded-xl p-4 gap-4 flex-col sm:flex-row md:flex-col md+:flex-row border-[0.5px] border-slate-200 shadow shadow-slate-300/50`,
                downtimeEnabled || `hidden`,
              )}
            >
              <span className="text-slate-500 font-medium">From</span>
              <TimeInput
                time={downtime.start}
                setTime={(start) => setDowntime({ ...downtime, start })}
              />
              <span className="text-slate-500 font-medium">to</span>
              <TimeInput
                time={downtime.end}
                setTime={(end) => setDowntime({ ...downtime, end })}
              />
            </div>
          </ToggleCard>
        </div>

        {blockedApps && (
          <div className="mt-12 max-w-3xl">
            <h2 className="text-lg font-bold text-slate-700">Blocked apps{` `}</h2>
            {blockedApps.length === 0 ? (
              <div className="flex flex-col items-center justify-center p-8 bg-slate-100 mt-2 rounded-2xl shadow-inner">
                <NoSymbolIcon className="w-8 h-8 text-slate-300" strokeWidth={2} />
                <h3 className="text-lg font-semibold text-slate-700 mt-2 mb-1">
                  No blocked apps
                </h3>
                <p className="text-slate-500 text-sm text-center">
                  Read more about what blocked apps are{` `}
                  <Link
                    to="https://gertrude.app/docs/block-mac-apps"
                    className="text-blue-500 font-medium underline"
                  >
                    here.
                  </Link>
                </p>
              </div>
            ) : (
              <div className="gap-1.5 my-2 flex flex-col">
                {blockedApps.map((app) => {
                  const resolved = resolveInstalledApp(app.identifier, installedApps);
                  return (
                    <BlockedAppCard
                      key={app.id}
                      app={app}
                      resolvedName={resolved?.name}
                      iconUrl={resolved?.iconUrl}
                      setSchedule={(schedule) => setBlockedAppSchedule(app.id, schedule)}
                      onDelete={() => removeBlockedApp(app.id)}
                    />
                  );
                })}
              </div>
            )}
            <form
              className="flex gap-2 mt-4"
              onSubmit={(e) => {
                e.preventDefault();
                addNewBlockedApp();
              }}
            >
              <TextInput
                key={`new-blocked-app-${blockedApps.length}`}
                type="text"
                value={newBlockedAppIdentifier}
                setValue={updateNewBlockedAppIdentifier}
                placeholder="App name or bundle id"
              />
              <Button
                size="small"
                className="whitespace-nowrap"
                color="secondary"
                type="submit"
                disabled={!newBlockedAppIdentifier}
              >
                <i className="fa fa-plus mr-2" />
                Add
              </Button>
            </form>
          </div>
        )}

        {supportsAlwaysBlocked && (
          <div className="mt-12 max-w-3xl">
            <h2 className="text-lg font-bold text-slate-700 mb-1">Always-Blocked</h2>
            <p className="text-slate-500 text-sm mb-4">
              These blocks apply at all times, even when the filter is suspended.
            </p>
            {availableAlwaysBlockedGroups.length > 0 && (
              <BlockGroupList
                title="Always-Blocked groups"
                groups={availableAlwaysBlockedGroups}
                enabledGroupIds={alwaysBlockedGroupIds}
                onToggle={toggleAlwaysBlockedGroup}
              />
            )}
            <div className={cx(availableAlwaysBlockedGroups.length > 0 && `mt-6`)}>
              <h3 className="text-base font-bold text-slate-700 mb-3">
                Custom Always-Blocked rules
              </h3>
              <div className="bg-white rounded-xl p-5 border-[0.5px] border-slate-200 shadow shadow-slate-300/50">
                <EditBlockRules
                  rules={customAlwaysBlockedRules
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
                  onAdd={addAlwaysBlockedRule}
                  onEdit={(id) => {
                    const entry = customAlwaysBlockedRules.find((r) => r.id === id);
                    if (!entry) return;
                    if (entry.rule.case !== `hostnameOrSubdomain`) return;
                    const props = convert.blockRuleToProps(entry.rule);
                    if (props) editAlwaysBlockedRule(id, props);
                  }}
                  onDelete={deleteAlwaysBlockedRule}
                />
              </div>
            </div>
          </div>
        )}

        <div className="mt-12 max-w-3xl">
          <h2 className="text-lg font-bold text-slate-700">Filtering</h2>
          {canDisableFilter && (
            <ToggleCard
              title="Filter internet access"
              description="Block all internet access except sites allowed by assigned keychains"
              enabled={!filteringDisabled}
              setEnabled={(enabled) => setFilteringDisabled(!enabled)}
              disabledReason={
                !screenshotsEnabled
                  ? `Internet filtering can only be disabled when screenshots are enabled`
                  : undefined
              }
              warning={
                filteringDisabled
                  ? `${childName} has unrestricted internet access and is only protected by ${keyloggingEnabled ? `screenshots and keylogging` : `screenshots`}`
                  : undefined
              }
            />
          )}
          {!filteringDisabled && (
            <div className="mt-4 flex flex-col space-y-4">
              {keychains.length === 0 ? (
                <EmptyState
                  heading={`No keychains`}
                  secondaryText={`By default, all internet access is blocked for this child until you assign a keychain.`}
                  icon={`key`}
                  buttonText={`Add keychain`}
                  action={onAddKeychainClicked}
                />
              ) : (
                <>
                  {keychains.map((keychain) => (
                    <KeychainCard
                      mode="assigned_to_child"
                      keychainId={keychain.id}
                      schedule={keychain.schedule}
                      key={keychain.id}
                      name={keychain.name}
                      description={keychain.description}
                      numKeys={keychain.numKeys}
                      isPublic={keychain.isPublic}
                      onRemove={() => removeKeychain(keychain.id)}
                      setSchedule={(schedule) =>
                        setAssignedKeychainSchedule(keychain.id, schedule)
                      }
                    />
                  ))}
                  <Button
                    type="button"
                    onClick={onAddKeychainClicked}
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

        <div className="flex mt-12 pt-8 border-t-2 border-slate-200 justify-end space-x-5">
          <Button
            className="ScrollTop"
            type="button"
            disabled={saveButtonDisabled}
            onClick={onSave}
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
            action: saveAlwaysBlockedRule,
            disabled:
              !editingAlwaysBlockedRule ||
              !validate.blockRuleProps(editingAlwaysBlockedRule),
          }}
          secondaryButton={{
            type: `action`,
            action: dismissAlwaysBlockedRule,
          }}
        >
          {editingAlwaysBlockedRule && (
            <BlockRuleEditor
              {...editingAlwaysBlockedRule}
              addressOnly
              emit={editAlwaysBlockedRuleForm}
            />
          )}
        </Modal>
      </>
    )}
  </div>
);

export default ChildMacSettingsLegacy;

function resolveInstalledApp(
  identifier: string,
  installedApps?: Array<{ bundleId: string; name: string; iconUrl?: string }>,
): { name: string; iconUrl?: string } | undefined {
  if (!installedApps || installedApps.length === 0) return undefined;
  const byBundleId = installedApps.find((app) => app.bundleId === identifier);
  if (byBundleId) return { name: byBundleId.name, iconUrl: byBundleId.iconUrl };
  const lowered = identifier.toLowerCase();
  const byName = installedApps.find((app) => app.name.toLowerCase() === lowered);
  if (byName) return { name: byName.name, iconUrl: byName.iconUrl };
  return undefined;
}
