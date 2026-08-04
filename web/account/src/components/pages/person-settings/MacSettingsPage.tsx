import {
  Button,
  Card,
  EmptyState,
  HStack,
  Input,
  Skeleton,
  Stack,
  Text,
  VStack,
} from '@gertrude/ui';
import {
  BanIcon,
  CircleAlertIcon,
  KeyIcon,
  LaptopIcon,
  PlusIcon,
  RefreshCwIcon,
  XIcon,
} from 'lucide-react';
import React from 'react';
import type { LoadableState, Schedule } from '#/components/types';
import CardContainer from '#/components/layout/CardContainer';
import AddBlockedDomainModal from '#/components/person-settings/AddBlockedDomainModal';
import AddKeychainSlideOver from '#/components/person-settings/AddKeychainSlideOver';
import BlockGroup from '#/components/person-settings/BlockGroup';
import KeychainCard from '#/components/person-settings/KeychainCard';
import PersonSettingsExpandableSection from '#/components/person-settings/PersonSettingsExpandableSection';
import SettingsRow from '#/components/person-settings/SettingsRow';

interface MacKeychain {
  id: string;
  name: string;
  description?: string;
  isPublic: boolean;
  numKeys: number;
  schedule?: Schedule;
}

interface AlwaysBlockedGroup {
  id: string;
  name: string;
  description: string;
  longDescription: string;
}

export interface MacSettingsConfiguration {
  keyloggingEnabled: boolean;
  showSuspensionActivity: boolean;
  screenshots: {
    enabled: boolean;
    resolution: number;
    frequency: number;
    canBeDisabled: boolean;
  };
  internetFiltering: {
    enabled: boolean;
    canBeDisabled: boolean;
    keychains: MacKeychain[];
    availableKeychains: MacKeychain[];
    supportsAlwaysBlocked: boolean;
    availableAlwaysBlockedGroups: AlwaysBlockedGroup[];
    alwaysBlockedGroupIds: string[];
    customAlwaysBlockedDomains: string[];
  };
  hasMacDevices: boolean;
}

export interface MacMonitoringConfiguration {
  keyloggingEnabled: boolean;
  showSuspensionActivity: boolean;
  screenshots: {
    enabled: boolean;
    resolution: number;
    frequency: number;
  };
}

interface InternetFilteringConfiguration {
  filteringEnabled: boolean;
  keychains: Array<{ id: string; schedule?: Schedule }>;
  alwaysBlockedGroupIds: string[];
  customAlwaysBlockedDomains: string[];
}

interface Props {
  state: LoadableState<MacSettingsConfiguration>;
  savingMonitoring?: boolean;
  savingInternetFiltering?: boolean;
  onSaveMonitoring: (configuration: MacMonitoringConfiguration) => void;
  onSaveInternetFiltering: (configuration: InternetFilteringConfiguration) => void;
  onUnsavedChangesChange?: (hasUnsavedChanges: boolean) => void;
}

interface MonitoringSettingsProps {
  settings: MacSettingsConfiguration;
  saving: boolean;
  onSave: (configuration: MacMonitoringConfiguration) => void;
  onUnsavedChangesChange: (hasUnsavedChanges: boolean) => void;
}

const integerAtLeast = (value: string, minimum: number): number | undefined => {
  const parsed = Number(value);
  return Number.isInteger(parsed) && parsed >= minimum ? parsed : undefined;
};

const MonitoringSettings: React.FC<MonitoringSettingsProps> = ({
  settings,
  saving,
  onSave,
  onUnsavedChangesChange,
}) => {
  const [keyloggingEnabled, setKeyloggingEnabled] = React.useState(
    settings.keyloggingEnabled,
  );
  const [screenshotsEnabled, setScreenshotsEnabled] = React.useState(
    settings.screenshots.enabled,
  );
  const [showSuspensionActivity, setShowSuspensionActivity] = React.useState(
    settings.showSuspensionActivity,
  );
  const [frequencyDraft, setFrequencyDraft] = React.useState(
    String(settings.screenshots.frequency),
  );
  const [resolutionDraft, setResolutionDraft] = React.useState(
    String(settings.screenshots.resolution),
  );
  const frequency = integerAtLeast(frequencyDraft, 10);
  const resolution = integerAtLeast(resolutionDraft, 1);
  const frequencyError =
    frequencyDraft.trim() === ``
      ? `Frequency is required.`
      : frequency === undefined
        ? `Enter a whole number of at least 10 seconds.`
        : undefined;
  const resolutionError =
    resolutionDraft.trim() === ``
      ? `Resolution is required.`
      : resolution === undefined
        ? `Enter a positive whole number.`
        : undefined;
  const hasUnsavedChanges =
    keyloggingEnabled !== settings.keyloggingEnabled ||
    screenshotsEnabled !== settings.screenshots.enabled ||
    showSuspensionActivity !== settings.showSuspensionActivity ||
    frequencyDraft !== String(settings.screenshots.frequency) ||
    resolutionDraft !== String(settings.screenshots.resolution);
  const screenshotRequirementMet =
    settings.screenshots.canBeDisabled || screenshotsEnabled;
  const canSave =
    hasUnsavedChanges &&
    frequency !== undefined &&
    resolution !== undefined &&
    screenshotRequirementMet;

  React.useEffect(() => {
    if (hasUnsavedChanges) {
      return;
    }

    setKeyloggingEnabled(settings.keyloggingEnabled);
    setScreenshotsEnabled(settings.screenshots.enabled);
    setShowSuspensionActivity(settings.showSuspensionActivity);
    setFrequencyDraft(String(settings.screenshots.frequency));
    setResolutionDraft(String(settings.screenshots.resolution));
  }, [
    hasUnsavedChanges,
    settings.keyloggingEnabled,
    settings.showSuspensionActivity,
    settings.screenshots.enabled,
    settings.screenshots.frequency,
    settings.screenshots.resolution,
  ]);

  React.useEffect(() => {
    onUnsavedChangesChange(hasUnsavedChanges);
  }, [hasUnsavedChanges, onUnsavedChangesChange]);

  const save = (): void => {
    if (
      !hasUnsavedChanges ||
      frequency === undefined ||
      resolution === undefined ||
      !screenshotRequirementMet ||
      saving
    ) {
      return;
    }

    setFrequencyDraft(String(frequency));
    setResolutionDraft(String(resolution));
    onSave({
      keyloggingEnabled,
      showSuspensionActivity,
      screenshots: {
        enabled: screenshotsEnabled,
        resolution,
        frequency,
      },
    });
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
              text: keyloggingEnabled ? `On` : `Off`,
              color: keyloggingEnabled ? `violet` : `neutral`,
            },
          ],
        },
        {
          title: `Screenshots`,
          values: [
            {
              text: screenshotsEnabled
                ? frequency === undefined
                  ? `On`
                  : `Every ${frequency}s`
                : `Off`,
              color: screenshotsEnabled ? `violet` : `neutral`,
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
            enabled={keyloggingEnabled}
            disabled={saving}
            setEnabled={setKeyloggingEnabled}
          />
          <SettingsRow
            type="toggle"
            title="Enable Screenshots"
            description={
              settings.screenshots.canBeDisabled
                ? `Periodically take a screenshot and upload it for your review.`
                : `Screenshots are required when internet filtering is disabled.`
            }
            enabled={screenshotsEnabled}
            disabled={
              saving || (screenshotsEnabled && !settings.screenshots.canBeDisabled)
            }
            setEnabled={(enabled) => {
              setScreenshotsEnabled(enabled);
              if (!enabled) {
                setFrequencyDraft(String(settings.screenshots.frequency));
                setResolutionDraft(String(settings.screenshots.resolution));
              }
            }}
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
                value={frequencyDraft}
                setValue={setFrequencyDraft}
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
                value={resolutionDraft}
                setValue={setResolutionDraft}
                min={1}
                step={1}
                error={resolutionError}
                disabled={saving}
                className="@lg/main:w-1/2"
              />
            </Stack>
          </SettingsRow>
          {(keyloggingEnabled || screenshotsEnabled) && (
            <SettingsRow
              type="toggle"
              title="Emphasize Filter Suspension Activity"
              description="Visually highlight activity that is recorded while filter is suspended."
              enabled={showSuspensionActivity}
              disabled={saving}
              setEnabled={setShowSuspensionActivity}
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
  saving: boolean;
  onSave: (configuration: InternetFilteringConfiguration) => void;
  onUnsavedChangesChange: (hasUnsavedChanges: boolean) => void;
}

const InternetFilteringSettings: React.FC<InternetFilteringSettingsProps> = ({
  settings,
  saving,
  onSave,
  onUnsavedChangesChange,
}) => {
  const [filteringEnabled, setFilteringEnabled] = React.useState(
    settings.internetFiltering.enabled,
  );
  const [keychains, setKeychains] = React.useState(settings.internetFiltering.keychains);
  const [alwaysBlockedGroupIds, setAlwaysBlockedGroupIds] = React.useState(
    settings.internetFiltering.alwaysBlockedGroupIds,
  );
  const [customAlwaysBlockedDomains, setCustomAlwaysBlockedDomains] = React.useState(
    settings.internetFiltering.customAlwaysBlockedDomains,
  );
  const [addBlockedDomainModalOpen, setAddBlockedDomainModalOpen] = React.useState(false);
  const [addKeychainSlideOverOpen, setAddKeychainSlideOverOpen] = React.useState(false);
  const hasUnsavedChanges =
    filteringEnabled !== settings.internetFiltering.enabled ||
    JSON.stringify(keychains) !== JSON.stringify(settings.internetFiltering.keychains) ||
    JSON.stringify(alwaysBlockedGroupIds) !==
      JSON.stringify(settings.internetFiltering.alwaysBlockedGroupIds) ||
    JSON.stringify(customAlwaysBlockedDomains) !==
      JSON.stringify(settings.internetFiltering.customAlwaysBlockedDomains);
  const canDisable =
    settings.internetFiltering.canBeDisabled && settings.screenshots.enabled;

  React.useEffect(() => {
    if (hasUnsavedChanges) {
      return;
    }

    setFilteringEnabled(settings.internetFiltering.enabled);
    setKeychains(settings.internetFiltering.keychains);
    setAlwaysBlockedGroupIds(settings.internetFiltering.alwaysBlockedGroupIds);
    setCustomAlwaysBlockedDomains(settings.internetFiltering.customAlwaysBlockedDomains);
  }, [
    hasUnsavedChanges,
    settings.internetFiltering.alwaysBlockedGroupIds,
    settings.internetFiltering.customAlwaysBlockedDomains,
    settings.internetFiltering.enabled,
    settings.internetFiltering.keychains,
  ]);

  React.useEffect(() => {
    onUnsavedChangesChange(hasUnsavedChanges);
  }, [hasUnsavedChanges, onUnsavedChangesChange]);

  const save = (): void => {
    if (!hasUnsavedChanges || saving || (!filteringEnabled && !canDisable)) {
      return;
    }

    onSave({
      filteringEnabled,
      keychains: keychains.map(({ id, schedule }) => ({ id, schedule })),
      alwaysBlockedGroupIds,
      customAlwaysBlockedDomains,
    });
  };

  return (
    <PersonSettingsExpandableSection
      title="Internet Filtering"
      hasUnsavedChanges={hasUnsavedChanges}
      previewChips={[
        {
          title: `Filter`,
          values: [
            {
              text: filteringEnabled ? `On` : `Off`,
              color: filteringEnabled ? `violet` : `neutral`,
            },
          ],
        },
        {
          title: `Keychains`,
          values: [
            {
              text: `${keychains.length}`,
              color: keychains.length > 0 ? `violet` : `neutral`,
            },
          ],
        },
        settings.internetFiltering.supportsAlwaysBlocked
          ? {
              title: `Always Blocked`,
              values: [
                {
                  text: `${alwaysBlockedGroupIds.length} groups`,
                  color: alwaysBlockedGroupIds.length > 0 ? `violet` : `neutral`,
                },
                {
                  text: `${customAlwaysBlockedDomains.length} domains`,
                  color: customAlwaysBlockedDomains.length > 0 ? `violet` : `neutral`,
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
            title="Filter Internet Access"
            description="Block internet access except sites allowed by assigned keychains."
            enabled={filteringEnabled}
            disabled={saving || (filteringEnabled && !canDisable)}
            setEnabled={setFilteringEnabled}
            warning={
              !settings.internetFiltering.canBeDisabled
                ? `Update every connected Mac before disabling internet filtering.`
                : !settings.screenshots.enabled
                  ? `Enable screenshots before disabling internet filtering.`
                  : undefined
            }
            showWarning={filteringEnabled && !canDisable}
          >
            {keychains.length > 0 ? (
              <VStack gap={3}>
                <div className="grid grid-cols-1 gap-3 @4xl/main:grid-cols-2 @6xl/main:grid-cols-3">
                  {keychains.map((keychain) => (
                    <KeychainCard
                      key={keychain.id}
                      name={keychain.name}
                      description={keychain.description}
                      numKeys={keychain.numKeys}
                      isPublic={keychain.isPublic}
                      schedule={keychain.schedule}
                      setSchedule={(schedule) =>
                        setKeychains((current) =>
                          current.map((currentKeychain) =>
                            currentKeychain.id === keychain.id
                              ? { ...currentKeychain, schedule }
                              : currentKeychain,
                          ),
                        )
                      }
                      onRemove={() =>
                        setKeychains((current) =>
                          current.filter(
                            (currentKeychain) => currentKeychain.id !== keychain.id,
                          ),
                        )
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
                    blocked={alwaysBlockedGroupIds.includes(group.id)}
                    setBlocked={(blocked) =>
                      setAlwaysBlockedGroupIds((current) =>
                        blocked
                          ? current.includes(group.id)
                            ? current
                            : [...current, group.id]
                          : current.filter((id) => id !== group.id),
                      )
                    }
                  />
                ))}
              </Card>
            </SettingsRow>
          )}
          {settings.internetFiltering.supportsAlwaysBlocked && (
            <SettingsRow
              type="alwaysOn"
              title="Custom Always Blocked Domains"
              description="These domains will be blocked at all times, even when the filter is suspended."
            >
              {customAlwaysBlockedDomains.length > 0 ? (
                <VStack gap={3}>
                  <HStack wrap gap={2}>
                    {customAlwaysBlockedDomains.map((domain) => (
                      <HStack
                        key={domain}
                        gap={2}
                        className="bg-white border p-1 pl-2.5 rounded-xl border-stone-200 shadow shadow-stone-300/30"
                      >
                        <BanIcon className="h-4 w-4 text-stone-500" />
                        <Text variant="body">{domain}</Text>
                        <Button
                          type="button"
                          onClick={() =>
                            setCustomAlwaysBlockedDomains((current) =>
                              current.filter((currentDomain) => currentDomain !== domain),
                            )
                          }
                          icon={XIcon}
                          ariaLabel={`Remove ${domain}`}
                          size="small"
                          variant="ghost"
                        />
                      </HStack>
                    ))}
                  </HStack>
                  <HStack justify="end">
                    <Button
                      type="button"
                      onClick={() => setAddBlockedDomainModalOpen(true)}
                      icon={PlusIcon}
                    >
                      Add Blocked Domain
                    </Button>
                  </HStack>
                </VStack>
              ) : (
                <EmptyState
                  icon={BanIcon}
                  title="No Always Blocked Domains"
                  description="Let's add some!"
                  button={{
                    text: `Add Blocked Domain`,
                    type: `button`,
                    onClick: () => setAddBlockedDomainModalOpen(true),
                    icon: PlusIcon,
                    variant: `primary`,
                  }}
                />
              )}
            </SettingsRow>
          )}
          <HStack justify="end">
            <Button
              type="submit"
              variant="primary"
              disabled={
                !hasUnsavedChanges || saving || (!filteringEnabled && !canDisable)
              }
              loading={saving}
              className="w-full @lg/main:w-auto"
            >
              Save Changes
            </Button>
          </HStack>
        </VStack>
      </form>
      <AddBlockedDomainModal
        open={addBlockedDomainModalOpen}
        onOpenChange={setAddBlockedDomainModalOpen}
        onAdd={(domain) =>
          setCustomAlwaysBlockedDomains((current) =>
            current.includes(domain) ? current : [...current, domain],
          )
        }
      />
      <AddKeychainSlideOver
        open={addKeychainSlideOverOpen}
        onOpenChange={setAddKeychainSlideOverOpen}
        personName="this person"
        keychains={settings.internetFiltering.availableKeychains}
        assignedKeychainIds={keychains.map((keychain) => keychain.id)}
        onAdd={(ids) =>
          setKeychains((current) => [
            ...current,
            ...settings.internetFiltering.availableKeychains.filter((keychain) =>
              ids.includes(keychain.id),
            ),
          ])
        }
      />
    </PersonSettingsExpandableSection>
  );
};

const MacSettingsPage: React.FC<Props> = ({
  state,
  savingMonitoring = false,
  savingInternetFiltering = false,
  onSaveMonitoring,
  onSaveInternetFiltering,
  onUnsavedChangesChange,
}) => {
  const [monitoringHasUnsavedChanges, setMonitoringHasUnsavedChanges] =
    React.useState(false);
  const [filteringHasUnsavedChanges, setFilteringHasUnsavedChanges] =
    React.useState(false);
  const hasUnsavedChanges =
    state.status === `success` &&
    state.data.hasMacDevices &&
    (monitoringHasUnsavedChanges || filteringHasUnsavedChanges);

  React.useEffect(() => {
    onUnsavedChangesChange?.(hasUnsavedChanges);
  }, [hasUnsavedChanges, onUnsavedChangesChange]);

  React.useEffect(
    () => () => {
      onUnsavedChangesChange?.(false);
    },
    [onUnsavedChangesChange],
  );

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
    <CardContainer className="flex flex-col gap-4">
      {(savingMonitoring || savingInternetFiltering) && (
        <span role="status" className="sr-only">
          Saving Mac settings
        </span>
      )}
      <MonitoringSettings
        settings={state.data}
        saving={savingMonitoring}
        onSave={onSaveMonitoring}
        onUnsavedChangesChange={setMonitoringHasUnsavedChanges}
      />
      <InternetFilteringSettings
        settings={state.data}
        saving={savingInternetFiltering}
        onSave={onSaveInternetFiltering}
        onUnsavedChangesChange={setFilteringHasUnsavedChanges}
      />
    </CardContainer>
  );
};

export default MacSettingsPage;
