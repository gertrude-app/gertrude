import {
  Button,
  Card,
  EmptyState,
  HStack,
  Input,
  Skeleton,
  Stack,
  VStack,
} from '@gertrude/ui';
import {
  CircleAlertIcon,
  KeyIcon,
  LaptopIcon,
  PlusIcon,
  RefreshCwIcon,
  SquareDashedIcon,
} from 'lucide-react';
import React from 'react';
import type { LoadableState } from '#/components/types';
import type {
  AppsFormState,
  InternetFilteringFormState,
  MacSettingsAction,
  MonitoringFormState,
} from './MacSettingsPage.reducer';
import type {
  InstalledMacApp,
  InternetFilteringConfiguration,
  MacAppsConfiguration,
  MacMonitoringConfiguration,
  MacSettingsConfiguration,
  UnrestrictedMacApp,
} from './MacSettingsPage.types';
import macSettingsReducer, {
  appsConfiguration,
  appsHaveUnsavedChanges,
  createMacSettingsFormState,
  defaultDowntime,
  internetFilteringConfiguration,
  internetFilteringHasUnsavedChanges,
  monitoringHasUnsavedChanges,
  monitoringSubmission,
  monitoringValidation,
} from './MacSettingsPage.reducer';
import CardContainer from '#/components/layout/CardContainer';
import AddKeychainSlideOver from '#/components/person-settings/AddKeychainSlideOver';
import AddMacAppSlideOver from '#/components/person-settings/AddMacAppSlideOver';
import AssignedKeychainCard from '#/components/person-settings/AssignedKeychainCard';
import BlockGroup from '#/components/person-settings/BlockGroup';
import ConfiguredAppRow from '#/components/person-settings/ConfiguredAppRow';
import CustomAlwaysBlockedRules from '#/components/person-settings/CustomAlwaysBlockedRules';
import PersonSettingsExpandableSection from '#/components/person-settings/PersonSettingsExpandableSection';
import SettingsRow from '#/components/person-settings/SettingsRow';
import {
  formatTime,
  inputValueToTimeOfDay,
  timeOfDayToInputValue,
} from '#/components/utils';

interface Props {
  state: LoadableState<MacSettingsConfiguration>;
  installedApps?: InstalledMacApp[];
  savingMonitoring?: boolean;
  savingInternetFiltering?: boolean;
  savingApps?: boolean;
  onSaveMonitoring: (configuration: MacMonitoringConfiguration) => void | Promise<void>;
  onSaveInternetFiltering: (
    configuration: InternetFilteringConfiguration,
  ) => void | Promise<void>;
  onSaveApps: (configuration: MacAppsConfiguration) => void | Promise<void>;
  onRequestPublicKeychain: (input: {
    searchQuery: string;
    description: string;
  }) => Promise<void>;
  onUnsavedChangesChange?: (hasUnsavedChanges: boolean) => void;
}

interface MonitoringSettingsProps {
  settings: MacSettingsConfiguration;
  state: MonitoringFormState;
  dispatch: React.Dispatch<MacSettingsAction>;
  saving: boolean;
  onSave: (configuration: MacMonitoringConfiguration) => void | Promise<void>;
}

const MonitoringSettings: React.FC<MonitoringSettingsProps> = ({
  settings,
  state,
  dispatch,
  saving,
  onSave,
}) => {
  const { draft } = state;
  const { frequency, resolution, frequencyError, resolutionError } =
    monitoringValidation(draft);
  const hasUnsavedChanges = monitoringHasUnsavedChanges(state);
  const screenshotRequirementMet =
    settings.screenshots.canBeDisabled || draft.screenshotsEnabled;
  const canSave =
    hasUnsavedChanges &&
    frequency !== undefined &&
    resolution !== undefined &&
    screenshotRequirementMet;

  const save = (): void => {
    const submission = monitoringSubmission(draft);
    if (!hasUnsavedChanges || !submission || !screenshotRequirementMet || saving) {
      return;
    }

    dispatch({ type: `monitoringSaveStarted`, submitted: submission.draft });
    void Promise.resolve(onSave(submission.configuration)).then(
      () => dispatch({ type: `monitoringSaveSucceeded`, submitted: submission.draft }),
      () => undefined,
    );
  };

  return (
    <PersonSettingsExpandableSection
      title="Monitoring"
      hasUnsavedChanges={hasUnsavedChanges}
      previewChips={[
        {
          title: `Keylogging`,
          values: [
            {
              text: draft.keyloggingEnabled ? `On` : `Off`,
              color: draft.keyloggingEnabled ? `violet` : `neutral`,
            },
          ],
        },
        {
          title: `Screenshots`,
          values: [
            {
              text: draft.screenshotsEnabled
                ? frequency === undefined
                  ? `On`
                  : `Every ${frequency}s`
                : `Off`,
              color: draft.screenshotsEnabled ? `violet` : `neutral`,
            },
          ],
        },
      ]}
    >
      <form
        onSubmit={(event) => {
          event.preventDefault();
          save();
        }}
      >
        <VStack gap={3}>
          <SettingsRow
            type="toggle"
            title="Enable Keylogging"
            description="Sends reports of all keystrokes to your review."
            enabled={draft.keyloggingEnabled}
            disabled={saving}
            setEnabled={(enabled) =>
              dispatch({ type: `monitoringKeyloggingChanged`, enabled })
            }
          />
          <SettingsRow
            type="toggle"
            title="Enable Screenshots"
            description={
              settings.screenshots.canBeDisabled
                ? `Periodically take a screenshot and upload it for your review.`
                : `Screenshots are required when internet filtering is disabled.`
            }
            enabled={draft.screenshotsEnabled}
            disabled={
              saving || (draft.screenshotsEnabled && !settings.screenshots.canBeDisabled)
            }
            setEnabled={(enabled) =>
              dispatch({ type: `monitoringScreenshotsChanged`, enabled })
            }
          >
            <Stack
              direction={{ default: `vertical`, '@lg/main': `horizontal` }}
              gap={{ default: 4, '@lg/main': 2 }}
            >
              <Input
                label="Average Frequency"
                suffix="seconds"
                prefix="Every"
                type="number"
                value={draft.frequencyDraft}
                setValue={(value) =>
                  dispatch({ type: `monitoringFrequencyChanged`, value })
                }
                min={10}
                step={1}
                error={frequencyError}
                helperText="The actual frequency will be randomized around the average you provide."
                disabled={saving}
                className="@lg/main:w-1/2"
              />
              <Input
                label="Resolution"
                suffix="px"
                type="number"
                value={draft.resolutionDraft}
                setValue={(value) =>
                  dispatch({ type: `monitoringResolutionChanged`, value })
                }
                min={1}
                step={1}
                error={resolutionError}
                disabled={saving}
                className="@lg/main:w-1/2"
              />
            </Stack>
          </SettingsRow>
          {(draft.keyloggingEnabled || draft.screenshotsEnabled) && (
            <SettingsRow
              type="toggle"
              title="Emphasize Filter Suspension Activity"
              description="Visually highlight activity that is recorded while filter is suspended."
              enabled={draft.showSuspensionActivity}
              disabled={saving}
              setEnabled={(enabled) =>
                dispatch({ type: `monitoringSuspensionActivityChanged`, enabled })
              }
            />
          )}
          <HStack justify="end">
            <Button
              type="submit"
              variant="primary"
              disabled={!canSave || saving}
              loading={saving}
              className="w-full @lg/main:w-auto"
            >
              Save Changes
            </Button>
          </HStack>
        </VStack>
      </form>
    </PersonSettingsExpandableSection>
  );
};

interface InternetFilteringSettingsProps {
  settings: MacSettingsConfiguration;
  state: InternetFilteringFormState;
  dispatch: React.Dispatch<MacSettingsAction>;
  saving: boolean;
  onSave: (configuration: InternetFilteringConfiguration) => void | Promise<void>;
  onRequestPublicKeychain: (input: {
    searchQuery: string;
    description: string;
  }) => Promise<void>;
}

const InternetFilteringSettings: React.FC<InternetFilteringSettingsProps> = ({
  settings,
  state,
  dispatch,
  saving,
  onSave,
  onRequestPublicKeychain,
}) => {
  const [addKeychainSlideOverOpen, setAddKeychainSlideOverOpen] = React.useState(false);
  const { draft } = state;
  const hasUnsavedChanges = internetFilteringHasUnsavedChanges(state);
  const canDisable =
    settings.internetFiltering.canBeDisabled && settings.screenshots.enabled;
  const downtime = draft.downtime ?? defaultDowntime;
  const downtimeError =
    draft.downtime &&
    draft.downtime.start.hour === draft.downtime.end.hour &&
    draft.downtime.start.minute === draft.downtime.end.minute
      ? `Start and end times must be different.`
      : undefined;

  const save = (): void => {
    if (
      !hasUnsavedChanges ||
      saving ||
      downtimeError ||
      (!draft.filteringEnabled && !canDisable)
    ) {
      return;
    }

    const submitted = draft;
    void Promise.resolve(onSave(internetFilteringConfiguration(submitted))).then(
      () => dispatch({ type: `internetFilteringSaveSucceeded`, submitted }),
      () => undefined,
    );
  };

  return (
    <PersonSettingsExpandableSection
      title="Internet Filtering"
      hasUnsavedChanges={hasUnsavedChanges}
      previewChips={[
        draft.downtime
          ? {
              title: `Downtime`,
              values: [
                {
                  text: `${formatTime(draft.downtime.start)} – ${formatTime(draft.downtime.end)}`,
                  color: `violet`,
                },
              ],
            }
          : null,
        {
          title: `Filter`,
          values: [
            {
              text: draft.filteringEnabled ? `On` : `Off`,
              color: draft.filteringEnabled ? `violet` : `neutral`,
            },
          ],
        },
        {
          title: `Keychains`,
          values: [
            {
              text: `${draft.keychains.length}`,
              color: draft.keychains.length > 0 ? `violet` : `neutral`,
            },
          ],
        },
        settings.internetFiltering.supportsAlwaysBlocked
          ? {
              title: `Always Blocked`,
              values: [
                {
                  text: `${draft.alwaysBlockedGroupIds.length} groups`,
                  color: draft.alwaysBlockedGroupIds.length > 0 ? `violet` : `neutral`,
                },
                {
                  text: `${draft.customAlwaysBlockedRules.length} rules`,
                  color: draft.customAlwaysBlockedRules.length > 0 ? `violet` : `neutral`,
                },
              ],
            }
          : null,
      ]}
    >
      <form
        onSubmit={(event) => {
          event.preventDefault();
          save();
        }}
      >
        <VStack gap={3}>
          <SettingsRow
            type="toggle"
            title="Enable Downtime"
            description="Completely restrict all internet access during specified hours."
            enabled={draft.downtime !== undefined}
            disabled={saving}
            setEnabled={(enabled) =>
              dispatch({ type: `downtimeEnabledChanged`, enabled })
            }
          >
            <Stack
              direction={{ default: `vertical`, '@lg/main': `horizontal` }}
              gap={{ default: 4, '@lg/main': 2 }}
            >
              <Input
                label="Start Time"
                type="time"
                value={timeOfDayToInputValue(downtime.start)}
                setValue={(value) => {
                  const start = inputValueToTimeOfDay(value);
                  if (start) {
                    dispatch({
                      type: `downtimeChanged`,
                      downtime: { ...downtime, start },
                    });
                  }
                }}
                disabled={saving}
                className="w-full @lg/main:w-1/2"
              />
              <Input
                label="End Time"
                type="time"
                value={timeOfDayToInputValue(downtime.end)}
                setValue={(value) => {
                  const end = inputValueToTimeOfDay(value);
                  if (end) {
                    dispatch({
                      type: `downtimeChanged`,
                      downtime: { ...downtime, end },
                    });
                  }
                }}
                error={downtimeError}
                disabled={saving}
                className="w-full @lg/main:w-1/2"
              />
            </Stack>
          </SettingsRow>
          <SettingsRow
            type="toggle"
            title="Filter Internet Access"
            description="Block internet access except sites allowed by assigned keychains."
            enabled={draft.filteringEnabled}
            disabled={saving || (draft.filteringEnabled && !canDisable)}
            setEnabled={(enabled) =>
              dispatch({ type: `filteringEnabledChanged`, enabled })
            }
            warning={
              !draft.filteringEnabled
                ? `Internet access is unrestricted and this person is only protected by ${settings.keyloggingEnabled ? `screenshots and keylogging` : `screenshots`}.`
                : !settings.internetFiltering.canBeDisabled
                  ? `Update every connected Mac before disabling internet filtering.`
                  : !settings.screenshots.enabled
                    ? `Enable screenshots before disabling internet filtering.`
                    : undefined
            }
            showWarning={!draft.filteringEnabled || !canDisable}
          >
            {draft.keychains.length > 0 ? (
              <VStack gap={3}>
                <div className="grid grid-cols-1 gap-3 @4xl/main:grid-cols-2 @6xl/main:grid-cols-3">
                  {draft.keychains.map((keychain) => (
                    <AssignedKeychainCard
                      key={keychain.id}
                      name={keychain.name}
                      description={keychain.description}
                      numKeys={keychain.numKeys}
                      isPublic={keychain.isPublic}
                      schedule={keychain.schedule}
                      setSchedule={(schedule) =>
                        dispatch({
                          type: `keychainScheduleChanged`,
                          id: keychain.id,
                          schedule,
                        })
                      }
                      onRemove={() =>
                        dispatch({ type: `keychainRemoved`, id: keychain.id })
                      }
                    />
                  ))}
                </div>
                <HStack justify="end">
                  <Button
                    type="button"
                    onClick={() => setAddKeychainSlideOverOpen(true)}
                    icon={PlusIcon}
                  >
                    Add Keychain
                  </Button>
                </HStack>
              </VStack>
            ) : (
              <EmptyState
                icon={KeyIcon}
                title="No Keychains"
                description="All internet access is blocked until you assign a keychain."
                button={{
                  text: `Add Keychain`,
                  type: `button`,
                  onClick: () => setAddKeychainSlideOverOpen(true),
                  icon: PlusIcon,
                  variant: `primary`,
                }}
              />
            )}
          </SettingsRow>
          {settings.internetFiltering.supportsAlwaysBlocked && (
            <SettingsRow
              type="alwaysOn"
              title="Always Blocked Groups"
              description="These block groups apply at all times, even when the filter is suspended."
            >
              <Card padding={0} className="overflow-hidden">
                {settings.internetFiltering.availableAlwaysBlockedGroups.map((group) => (
                  <BlockGroup
                    key={group.id}
                    title={group.name}
                    shortDescription={group.description}
                    longExplanation={group.longDescription}
                    blocked={draft.alwaysBlockedGroupIds.includes(group.id)}
                    setBlocked={(blocked) =>
                      dispatch({
                        type: `alwaysBlockedGroupChanged`,
                        id: group.id,
                        blocked,
                      })
                    }
                  />
                ))}
              </Card>
            </SettingsRow>
          )}
          {settings.internetFiltering.supportsAlwaysBlocked && (
            <SettingsRow
              type="alwaysOn"
              title="Custom Always Blocked Rules"
              description="These rules apply at all times, even when the filter is suspended."
            >
              <CustomAlwaysBlockedRules
                rules={draft.customAlwaysBlockedRules}
                onChange={(rules) =>
                  dispatch({ type: `customAlwaysBlockedRulesChanged`, rules })
                }
              />
            </SettingsRow>
          )}
          <HStack justify="end">
            <Button
              type="submit"
              variant="primary"
              disabled={
                !hasUnsavedChanges ||
                saving ||
                !!downtimeError ||
                (!draft.filteringEnabled && !canDisable)
              }
              loading={saving}
              className="w-full @lg/main:w-auto"
            >
              Save Changes
            </Button>
          </HStack>
        </VStack>
      </form>
      <AddKeychainSlideOver
        open={addKeychainSlideOverOpen}
        onOpenChange={setAddKeychainSlideOverOpen}
        personName="this person"
        keychains={settings.internetFiltering.availableKeychains}
        assignedKeychainIds={draft.keychains.map((keychain) => keychain.id)}
        onRequestPublicKeychain={onRequestPublicKeychain}
        onAdd={(ids) =>
          dispatch({
            type: `keychainsAdded`,
            keychains: settings.internetFiltering.availableKeychains.filter((keychain) =>
              ids.includes(keychain.id),
            ),
          })
        }
      />
    </PersonSettingsExpandableSection>
  );
};

interface AppsSettingsProps {
  state: AppsFormState;
  installedApps: InstalledMacApp[];
  dispatch: React.Dispatch<MacSettingsAction>;
  saving: boolean;
  onSave: (configuration: MacAppsConfiguration) => void | Promise<void>;
}

const AppsSettings: React.FC<AppsSettingsProps> = ({
  state,
  installedApps,
  dispatch,
  saving,
  onSave,
}) => {
  const [addAppSlideOverType, setAddAppSlideOverType] = React.useState<
    `blocked` | `unrestricted` | null
  >(null);
  const { draft } = state;
  const hasUnsavedChanges = appsHaveUnsavedChanges(state);
  const isAlwaysBlocked = (scope: UnrestrictedMacApp[`scope`]): boolean => {
    const installedApp = installedApps.find((app) =>
      scope.type === `identifiedAppSlug`
        ? app.identifiedAppSlug === scope.identifiedAppSlug
        : app.bundleId === scope.bundleId,
    );
    if (!installedApp) {
      return false;
    }

    return draft.blocked.some(
      (blockedApp) =>
        blockedApp.schedule === undefined &&
        (blockedApp.identifier === installedApp.bundleId ||
          blockedApp.identifier.toLowerCase() === installedApp.name.toLowerCase()),
    );
  };

  const save = (): void => {
    if (!hasUnsavedChanges || saving) {
      return;
    }

    const submitted = draft;
    void Promise.resolve(onSave(appsConfiguration(submitted))).then(
      () => dispatch({ type: `appsSaveSucceeded`, submitted }),
      () => undefined,
    );
  };

  return (
    <PersonSettingsExpandableSection
      title="Apps"
      hasUnsavedChanges={hasUnsavedChanges}
      previewChips={[
        {
          title: `Blocked Apps`,
          values: [
            {
              text: `${draft.blocked.length}`,
              color: draft.blocked.length > 0 ? `violet` : `neutral`,
            },
          ],
        },
        {
          title: `Unrestricted Apps`,
          values: [
            {
              text: `${draft.unrestricted.length + draft.publicUnrestricted.length}`,
              color:
                draft.unrestricted.length + draft.publicUnrestricted.length > 0
                  ? `violet`
                  : `neutral`,
            },
          ],
        },
      ]}
    >
      <form
        onSubmit={(event) => {
          event.preventDefault();
          save();
        }}
      >
        <VStack gap={3}>
          <SettingsRow
            type="alwaysOn"
            title="Blocked Apps"
            description="These apps can't open at all. Add a schedule to only block them at certain times."
          >
            {draft.blocked.length > 0 ? (
              <VStack gap={3}>
                {draft.blocked.map((app) => (
                  <ConfiguredAppRow
                    key={app.id}
                    app={{
                      name: app.name ?? app.identifier,
                      appIconUrl: app.appIconUrl,
                      schedule: app.schedule,
                    }}
                    setSchedule={(schedule) =>
                      dispatch({
                        type: `blockedAppScheduleChanged`,
                        id: app.id,
                        schedule,
                      })
                    }
                    onRemove={() => dispatch({ type: `blockedAppRemoved`, id: app.id })}
                  />
                ))}
                <HStack justify="end">
                  <Button
                    type="button"
                    onClick={() => setAddAppSlideOverType(`blocked`)}
                    icon={PlusIcon}
                    disabled={saving || installedApps.length === 0}
                  >
                    Add Blocked App
                  </Button>
                </HStack>
              </VStack>
            ) : (
              <EmptyState
                icon={SquareDashedIcon}
                title="No Blocked Apps"
                description={
                  installedApps.length > 0
                    ? `Choose apps that shouldn't be able to open.`
                    : `No installed apps have been reported yet.`
                }
                button={
                  installedApps.length > 0
                    ? {
                        text: `Add Blocked App`,
                        type: `button`,
                        onClick: () => setAddAppSlideOverType(`blocked`),
                        icon: PlusIcon,
                        variant: `primary`,
                      }
                    : undefined
                }
              />
            )}
          </SettingsRow>
          <SettingsRow
            type="alwaysOn"
            title="Apps With Unrestricted Internet Access"
            description="By default apps can't reach the internet. These apps are granted full, unrestricted access. Add a schedule to limit when they can connect."
          >
            {draft.unrestricted.length + draft.publicUnrestricted.length > 0 ? (
              <VStack gap={3}>
                {draft.unrestricted.map((app) => (
                  <ConfiguredAppRow
                    key={app.id}
                    app={{
                      name:
                        app.name ??
                        (app.scope.type === `identifiedAppSlug`
                          ? app.scope.identifiedAppSlug
                          : app.scope.bundleId),
                      appIconUrl: app.appIconUrl,
                      schedule: app.schedule,
                    }}
                    ineffective={isAlwaysBlocked(app.scope)}
                    statusLabel="Unrestricted Internet"
                    setSchedule={(schedule) =>
                      dispatch({
                        type: `unrestrictedAppScheduleChanged`,
                        id: app.id,
                        schedule,
                      })
                    }
                    onRemove={() =>
                      dispatch({ type: `unrestrictedAppRemoved`, id: app.id })
                    }
                  />
                ))}
                {draft.publicUnrestricted.map((app, index) => (
                  <ConfiguredAppRow
                    key={`${app.keychainId}-${JSON.stringify(app.scope)}-${index}`}
                    app={{
                      name:
                        app.name ??
                        (app.scope.type === `identifiedAppSlug`
                          ? app.scope.identifiedAppSlug
                          : app.scope.bundleId),
                      appIconUrl: app.appIconUrl,
                      schedule: app.schedule,
                    }}
                    sourceLabel={app.keychainName}
                    ineffective={isAlwaysBlocked(app.scope)}
                    statusLabel="Unrestricted Internet"
                  />
                ))}
                <HStack justify="end">
                  <Button
                    type="button"
                    onClick={() => setAddAppSlideOverType(`unrestricted`)}
                    icon={PlusIcon}
                    disabled={saving || installedApps.length === 0}
                  >
                    Add Unrestricted App
                  </Button>
                </HStack>
              </VStack>
            ) : (
              <EmptyState
                icon={SquareDashedIcon}
                title="No Unrestricted Apps"
                description={
                  installedApps.length > 0
                    ? `Choose apps that should have unrestricted internet access.`
                    : `No installed apps have been reported yet.`
                }
                button={
                  installedApps.length > 0
                    ? {
                        text: `Add Unrestricted App`,
                        type: `button`,
                        onClick: () => setAddAppSlideOverType(`unrestricted`),
                        icon: PlusIcon,
                        variant: `primary`,
                      }
                    : undefined
                }
              />
            )}
          </SettingsRow>
          <HStack justify="end">
            <Button
              type="submit"
              variant="primary"
              disabled={!hasUnsavedChanges || saving}
              loading={saving}
              className="w-full @lg/main:w-auto"
            >
              Save Changes
            </Button>
          </HStack>
        </VStack>
      </form>
      {addAppSlideOverType && (
        <AddMacAppSlideOver
          open
          type={addAppSlideOverType}
          personName="this person"
          installedApps={installedApps}
          blockedApps={draft.blocked}
          unrestrictedApps={draft.unrestricted}
          publicUnrestrictedApps={draft.publicUnrestricted}
          onOpenChange={(open) => {
            if (!open) {
              setAddAppSlideOverType(null);
            }
          }}
          onAdd={(apps) => {
            if (addAppSlideOverType === `blocked`) {
              dispatch({
                type: `blockedAppsAdded`,
                apps: apps.map((app) => ({
                  id: crypto.randomUUID(),
                  identifier: app.bundleId,
                  name: app.name,
                  appIconUrl: app.appIconUrl,
                })),
              });
            } else {
              dispatch({
                type: `unrestrictedAppsAdded`,
                apps: apps.map((app) => ({
                  id: crypto.randomUUID(),
                  scope: app.identifiedAppSlug
                    ? {
                        type: `identifiedAppSlug`,
                        identifiedAppSlug: app.identifiedAppSlug,
                      }
                    : { type: `bundleId`, bundleId: app.bundleId },
                  name: app.name,
                  appIconUrl: app.appIconUrl,
                })),
              });
            }
          }}
        />
      )}
    </PersonSettingsExpandableSection>
  );
};

interface MacSettingsEditorProps {
  settings: MacSettingsConfiguration;
  installedApps: InstalledMacApp[];
  savingMonitoring: boolean;
  savingInternetFiltering: boolean;
  savingApps: boolean;
  onSaveMonitoring: (configuration: MacMonitoringConfiguration) => void | Promise<void>;
  onSaveInternetFiltering: (
    configuration: InternetFilteringConfiguration,
  ) => void | Promise<void>;
  onSaveApps: (configuration: MacAppsConfiguration) => void | Promise<void>;
  onRequestPublicKeychain: (input: {
    searchQuery: string;
    description: string;
  }) => Promise<void>;
  onUnsavedChangesChange?: (hasUnsavedChanges: boolean) => void;
}

const MacSettingsEditor: React.FC<MacSettingsEditorProps> = ({
  settings,
  installedApps,
  savingMonitoring,
  savingInternetFiltering,
  savingApps,
  onSaveMonitoring,
  onSaveInternetFiltering,
  onSaveApps,
  onRequestPublicKeychain,
  onUnsavedChangesChange,
}) => {
  const hydratedSettings = React.useMemo<MacSettingsConfiguration>(
    () => ({
      ...settings,
      apps: {
        ...settings.apps,
        blocked: settings.apps.blocked.map((blockedApp) => {
          const lowerIdentifier = blockedApp.identifier.toLowerCase();
          const installedApp = installedApps.find(
            (app) =>
              app.bundleId === blockedApp.identifier ||
              app.name.toLowerCase() === lowerIdentifier,
          );
          return installedApp
            ? {
                ...blockedApp,
                name: installedApp.name,
                appIconUrl: installedApp.appIconUrl,
              }
            : blockedApp;
        }),
        unrestricted: settings.apps.unrestricted.map((unrestrictedApp) => {
          const installedApp = installedApps.find((app) =>
            unrestrictedApp.scope.type === `identifiedAppSlug`
              ? app.identifiedAppSlug === unrestrictedApp.scope.identifiedAppSlug
              : app.bundleId === unrestrictedApp.scope.bundleId,
          );
          return installedApp
            ? {
                ...unrestrictedApp,
                name: installedApp.name,
                appIconUrl: installedApp.appIconUrl,
              }
            : unrestrictedApp;
        }),
        publicUnrestricted: settings.apps.publicUnrestricted.map(
          (publicUnrestrictedApp) => {
            const installedApp = installedApps.find((app) =>
              publicUnrestrictedApp.scope.type === `identifiedAppSlug`
                ? app.identifiedAppSlug === publicUnrestrictedApp.scope.identifiedAppSlug
                : app.bundleId === publicUnrestrictedApp.scope.bundleId,
            );
            return installedApp
              ? {
                  ...publicUnrestrictedApp,
                  name: installedApp.name,
                  appIconUrl: installedApp.appIconUrl,
                }
              : publicUnrestrictedApp;
          },
        ),
      },
    }),
    [installedApps, settings],
  );
  const [formState, dispatch] = React.useReducer(
    macSettingsReducer,
    hydratedSettings,
    createMacSettingsFormState,
  );
  const monitoringHasChanges = monitoringHasUnsavedChanges(formState.monitoring);
  const internetFilteringHasChanges = internetFilteringHasUnsavedChanges(
    formState.internetFiltering,
  );
  const appsHaveChanges = appsHaveUnsavedChanges(formState.apps);
  const hasUnsavedChanges =
    monitoringHasChanges || internetFilteringHasChanges || appsHaveChanges;

  React.useEffect(() => {
    dispatch({ type: `settingsReceived`, settings: hydratedSettings });
  }, [
    appsHaveChanges,
    hydratedSettings,
    internetFilteringHasChanges,
    monitoringHasChanges,
  ]);

  React.useEffect(() => {
    onUnsavedChangesChange?.(hasUnsavedChanges);
  }, [hasUnsavedChanges, onUnsavedChangesChange]);

  React.useEffect(
    () => () => {
      onUnsavedChangesChange?.(false);
    },
    [onUnsavedChangesChange],
  );

  return (
    <CardContainer className="flex flex-col gap-4">
      {(savingMonitoring || savingInternetFiltering || savingApps) && (
        <span role="status" className="sr-only">
          Saving Mac settings
        </span>
      )}
      <MonitoringSettings
        settings={settings}
        state={formState.monitoring}
        dispatch={dispatch}
        saving={savingMonitoring}
        onSave={onSaveMonitoring}
      />
      <InternetFilteringSettings
        settings={settings}
        state={formState.internetFiltering}
        dispatch={dispatch}
        saving={savingInternetFiltering}
        onSave={onSaveInternetFiltering}
        onRequestPublicKeychain={onRequestPublicKeychain}
      />
      <AppsSettings
        state={formState.apps}
        installedApps={installedApps}
        dispatch={dispatch}
        saving={savingApps}
        onSave={onSaveApps}
      />
    </CardContainer>
  );
};

const MacSettingsPage: React.FC<Props> = ({
  state,
  installedApps = [],
  savingMonitoring = false,
  savingInternetFiltering = false,
  savingApps = false,
  onSaveMonitoring,
  onSaveInternetFiltering,
  onSaveApps,
  onRequestPublicKeychain,
  onUnsavedChangesChange,
}) => {
  if (state.status === `loading`) {
    return (
      <CardContainer className="flex flex-col gap-4">
        <span role="status" className="sr-only">
          Loading Mac settings
        </span>
        <Skeleton className="h-14 w-full" radius="large" />
        <Skeleton className="h-28 w-full" radius="large" />
      </CardContainer>
    );
  }

  if (state.status === `error`) {
    return (
      <CardContainer>
        <div role="alert">
          <EmptyState
            icon={CircleAlertIcon}
            title="Couldn't load Mac settings"
            description={state.message}
            button={{
              text: `Try again`,
              type: `button`,
              onClick: state.onRetry,
              icon: RefreshCwIcon,
            }}
            className="bg-white"
          />
        </div>
      </CardContainer>
    );
  }

  if (!state.data.hasMacDevices) {
    return (
      <CardContainer>
        <EmptyState
          icon={LaptopIcon}
          title="No Mac connected"
          description="Connect a Mac to configure its monitoring settings."
          className="bg-white"
        />
      </CardContainer>
    );
  }

  return (
    <MacSettingsEditor
      settings={state.data}
      installedApps={installedApps}
      savingMonitoring={savingMonitoring}
      savingInternetFiltering={savingInternetFiltering}
      savingApps={savingApps}
      onSaveMonitoring={onSaveMonitoring}
      onSaveInternetFiltering={onSaveInternetFiltering}
      onSaveApps={onSaveApps}
      onRequestPublicKeychain={onRequestPublicKeychain}
      onUnsavedChangesChange={onUnsavedChangesChange}
    />
  );
};

export default MacSettingsPage;
