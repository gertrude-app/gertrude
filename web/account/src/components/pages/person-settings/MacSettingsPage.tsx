import {
  Button,
  Card,
  EmptyState,
  HStack,
  Input,
  Stack,
  Text,
  VStack,
} from '@gertrude/ui';
import { BanIcon, KeyIcon, PlusIcon, SquareDashedIcon, XIcon } from 'lucide-react';
import React from 'react';
import type {
  ConfiguredMacApp,
  InstalledMacApp,
  Keychain,
  PersonMacSettingsConfiguration,
} from '#/components/types';
import CardContainer from '#/components/layout/CardContainer';
import AddBlockedDomainModal from '#/components/person-settings/AddBlockedDomainModal';
import AddKeychainSlideOver from '#/components/person-settings/AddKeychainSlideOver';
import AddMacAppSlideOver from '#/components/person-settings/AddMacAppSlideOver';
import BlockGroup from '#/components/person-settings/BlockGroup';
import ConfiguredAppRow from '#/components/person-settings/ConfiguredAppRow';
import KeychainCard from '#/components/person-settings/KeychainCard';
import PersonSettingsExpandableSection from '#/components/person-settings/PersonSettingsExpandableSection';
import SettingsRow from '#/components/person-settings/SettingsRow';
import {
  formatTime,
  inputValueToTimeOfDay,
  timeOfDayToInputValue,
} from '#/components/utils';

type MacSettingsSection = `monitoring` | `filtering` | `apps`;

interface Props {
  config?: PersonMacSettingsConfiguration;
  personName: string;
  hasMacDevices: boolean;
  assignedKeychains: Keychain[];
  allKeychains: Keychain[];
  installedMacApps: InstalledMacApp[];
  defaultExpandedSections?: MacSettingsSection[];
  patchConfig: (patch: Partial<PersonMacSettingsConfiguration>) => void;
}

const defaultDowntime: NonNullable<PersonMacSettingsConfiguration[`downtime`]> = {
  start: { hour: 9, minute: 0 },
  end: { hour: 17, minute: 0 },
};
const emptyDefaultExpandedSections: MacSettingsSection[] = [];

const MacSettingsPage: React.FC<Props> = ({
  config,
  personName,
  hasMacDevices,
  assignedKeychains,
  allKeychains,
  installedMacApps,
  defaultExpandedSections = emptyDefaultExpandedSections,
  patchConfig,
}) => {
  const [addBlockedDomainModalOpen, setAddBlockedDomainModalOpen] = React.useState(false);
  const [addKeychainSlideOverOpen, setAddKeychainSlideOverOpen] = React.useState(false);
  const [addAppSlideOverType, setAddAppSlideOverType] = React.useState<
    `blocked` | `unrestricted` | null
  >(null);

  if (!config || !hasMacDevices) {
    return (
      <CardContainer className="flex flex-col gap-4">
        <Text variant="bodyMuted" className="text-center">
          No Mac settings to configure.
        </Text>
      </CardContainer>
    );
  }

  const patchDowntime = (
    patch: Partial<NonNullable<PersonMacSettingsConfiguration[`downtime`]>>,
  ): void => {
    patchConfig({ downtime: { ...(config.downtime ?? defaultDowntime), ...patch } });
  };
  const alwaysBlockedGroupCount = Object.values(config.alwaysBlockedGroups).filter(
    Boolean,
  ).length;
  const addCustomAlwaysBlockedDomain = (domain: string): void => {
    if (config.customAlwaysBlockedDomains.includes(domain)) {
      return;
    }

    patchConfig({
      customAlwaysBlockedDomains: [...config.customAlwaysBlockedDomains, domain],
    });
  };
  const addSelectedInstalledApps = (
    type: `blocked` | `unrestricted`,
    apps: InstalledMacApp[],
  ): void => {
    const appsToAdd: ConfiguredMacApp[] = apps.map((app) => ({
      nameOrBundleId: app.name,
      appIconUrl: app.appIconUrl,
    }));

    if (type === `blocked`) {
      patchConfig({ blockedApps: [...config.blockedApps, ...appsToAdd] });
    } else {
      patchConfig({ unrestrictedApps: [...config.unrestrictedApps, ...appsToAdd] });
    }
  };
  const addKeychains = (keychainIds: string[]): void => {
    patchConfig({
      keychainIds: [
        ...config.keychainIds,
        ...keychainIds.filter((keychainId) => !config.keychainIds.includes(keychainId)),
      ],
    });
  };

  return (
    <>
      <CardContainer className="flex flex-col gap-4">
        <PersonSettingsExpandableSection
          title="Monitoring"
          defaultExpanded={defaultExpandedSections.includes(`monitoring`)}
          previewChips={[
            {
              title: `Keylogging`,
              values: [
                {
                  text: config.keyloggingEnabled ? `On` : `Off`,
                  color: config.keyloggingEnabled ? `violet` : `neutral`,
                },
              ],
            },
            {
              title: `Screenshots`,
              values: [
                {
                  text: config.screenshots
                    ? `Every ${config.screenshots.frequency}s`
                    : `Off`,
                  color: config.screenshots ? `violet` : `neutral`,
                },
              ],
            },
          ]}
        >
          <VStack gap={3}>
            <SettingsRow
              type="toggle"
              title="Enable Keylogging"
              description="Sends reports of all keystrokes to your review."
              enabled={config.keyloggingEnabled}
              setEnabled={(enabled) => patchConfig({ keyloggingEnabled: enabled })}
            />
            <SettingsRow
              type="toggle"
              title="Enable Screenshots"
              description={
                config.filteringOn
                  ? `Periodically take a screenshot and upload for your review.`
                  : `Screenshots are required when internet filtering is disabled.`
              }
              enabled={config.screenshots !== undefined}
              setEnabled={(enabled) =>
                patchConfig({
                  screenshots: enabled
                    ? (config.screenshots ?? { resolution: 1080, frequency: 120 })
                    : undefined,
                })
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
                  value={String(config.screenshots?.frequency || 0)}
                  setValue={(value) =>
                    patchConfig({
                      screenshots: {
                        ...(config.screenshots ?? { resolution: 1080, frequency: 120 }),
                        frequency: Number(value),
                      },
                    })
                  }
                  helperText="The actual frequency will be randomized around the average you provide."
                  className="@lg/main:w-1/2"
                />
                <Input
                  label="Resolution"
                  suffix="px"
                  type="number"
                  value={String(config.screenshots?.resolution || 0)}
                  setValue={(value) =>
                    patchConfig({
                      screenshots: {
                        ...(config.screenshots ?? { resolution: 1080, frequency: 120 }),
                        resolution: Number(value),
                      },
                    })
                  }
                  className="@lg/main:w-1/2"
                />
              </Stack>
            </SettingsRow>
            {(config.keyloggingEnabled || config.screenshots) && (
              <SettingsRow
                type="toggle"
                title="Emphasize Filter Suspension Activity"
                description="Visually highlight activity that is recorded while filter is suspended."
                enabled={config.emphasizeSuspensionActivity}
                setEnabled={(enabled) =>
                  patchConfig({ emphasizeSuspensionActivity: enabled })
                }
              />
            )}
          </VStack>
        </PersonSettingsExpandableSection>
        <PersonSettingsExpandableSection
          title="Internet Filtering"
          defaultExpanded={defaultExpandedSections.includes(`filtering`)}
          previewChips={[
            config.downtime
              ? {
                  title: `Downtime`,
                  values: [
                    {
                      text: `${formatTime(config.downtime.start)} – ${formatTime(config.downtime.end)}`,
                      color: `violet`,
                    },
                  ],
                }
              : null,
            {
              title: `Filter`,
              values: [
                {
                  text: config.filteringOn ? `On` : `Off`,
                  color: config.filteringOn ? `violet` : `neutral`,
                },
                {
                  text: `${config.keychainIds.length} Keychains`,
                  color: config.keychainIds.length > 0 ? `violet` : `neutral`,
                },
              ],
            },
            {
              title: `Always Blocked`,
              values: [
                {
                  text: `${alwaysBlockedGroupCount} groups`,
                  color: alwaysBlockedGroupCount > 0 ? `violet` : `neutral`,
                },
                {
                  text: `${config.customAlwaysBlockedDomains.length} domains`,
                  color:
                    config.customAlwaysBlockedDomains.length > 0 ? `violet` : `neutral`,
                },
              ],
            },
          ]}
        >
          <VStack gap={3}>
            <SettingsRow
              type="toggle"
              title="Enable Downtime"
              description="Completely restrict all internet access during specified hours"
              enabled={config.downtime !== undefined}
              setEnabled={(enabled) =>
                patchConfig({ downtime: enabled ? defaultDowntime : undefined })
              }
            >
              <HStack gap={2}>
                <Input
                  label="Start Time"
                  type="time"
                  value={timeOfDayToInputValue(
                    config.downtime?.start ?? defaultDowntime.start,
                  )}
                  setValue={(value) => {
                    const start = inputValueToTimeOfDay(value);

                    if (start) {
                      patchDowntime({ start });
                    }
                  }}
                  className="w-1/2"
                />
                <Input
                  label="End Time"
                  type="time"
                  value={timeOfDayToInputValue(
                    config.downtime?.end ?? defaultDowntime.end,
                  )}
                  setValue={(value) => {
                    const end = inputValueToTimeOfDay(value);

                    if (end) {
                      patchDowntime({ end });
                    }
                  }}
                  className="w-1/2"
                />
              </HStack>
            </SettingsRow>
            <SettingsRow
              type="toggle"
              title="Filter Internet Access"
              description="Block all internet access except sites allowed by assigned keychains"
              enabled={config.filteringOn}
              setEnabled={(enabled) => patchConfig({ filteringOn: enabled })}
            >
              {assignedKeychains.length > 0 ? (
                <VStack gap={3}>
                  <div className="grid grid-cols-1 gap-3 @4xl/main:grid-cols-2 @6xl/main:grid-cols-3">
                    {assignedKeychains.map((keychain) => (
                      <KeychainCard
                        key={keychain.id}
                        name={keychain.name}
                        description={keychain.description}
                        numKeys={keychain.numKeys}
                        isPublic={keychain.isPublic}
                        schedule={config.keychainSchedules?.[keychain.id]}
                        setSchedule={(schedule) =>
                          patchConfig({
                            keychainSchedules: {
                              ...config.keychainSchedules,
                              [keychain.id]: schedule,
                            },
                          })
                        }
                        onRemove={() =>
                          patchConfig({
                            keychainIds: config.keychainIds.filter(
                              (id) => id !== keychain.id,
                            ),
                          })
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
                  description="By default, all internet access is blocked for this child until you assign a keychain."
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
            <SettingsRow
              type="alwaysOn"
              title="Always Blocked Groups"
              description="These block groups will apply at all times, even when the filter is suspended."
            >
              <Card padding={0} className="overflow-hidden">
                <BlockGroup
                  title="Adult Content"
                  shortDescription="Block the most-trafficked adult websites, plus adult-oriented TLDs."
                  longExplanation="Blocks roughly 50 of the most-trafficked adult sites by current web traffic, plus the adult-oriented top-level domains .xxx, .porn, .adult, and .sex — any site on those TLDs is blocked wholesale. The open adult web shifts constantly, so this list is a best-effort snapshot and not exhaustive. You can add your own custom blocks alongside this group."
                  blocked={config.alwaysBlockedGroups.adultContent}
                  setBlocked={(blocked) =>
                    patchConfig({
                      alwaysBlockedGroups: {
                        ...config.alwaysBlockedGroups,
                        adultContent: blocked,
                      },
                    })
                  }
                />
                <BlockGroup
                  title="Messages GIF Search"
                  shortDescription="Block the #images GIF picker in Messages and common GIF providers."
                  longExplanation="Prevents access to the #images GIF picker inside the macOS Messages app, plus the major GIF content providers (Giphy, Tenor) and Apple's GIF CDN. Also blocks Signal's GIF proxy."
                  blocked={config.alwaysBlockedGroups.messagesGifSearch}
                  setBlocked={(blocked) =>
                    patchConfig({
                      alwaysBlockedGroups: {
                        ...config.alwaysBlockedGroups,
                        messagesGifSearch: blocked,
                      },
                    })
                  }
                />
                <BlockGroup
                  title="Social Media"
                  shortDescription="Block the most prominent social media sites."
                  longExplanation="Blocks Instagram, TikTok, X (Twitter), Facebook, Snapchat, Threads, and Pinterest. If this list doesn't work for you, you can add your own custom social media blocks as well."
                  blocked={config.alwaysBlockedGroups.socialMedia}
                  setBlocked={(blocked) =>
                    patchConfig({
                      alwaysBlockedGroups: {
                        ...config.alwaysBlockedGroups,
                        socialMedia: blocked,
                      },
                    })
                  }
                />
                <BlockGroup
                  title="Spotlight Search"
                  shortDescription="Block web results in macOS Spotlight search."
                  longExplanation="Blocks Spotlight's web-backed results (Siri Suggestions, web images, web snippets). Spotlight's web access is particularly worth blocking because a search initiated during a filter suspension can keep its HTTP connection alive after the suspension ends, letting it continue to fetch web results through the already-approved connection. Blocking Spotlight at the app level closes that loophole."
                  blocked={config.alwaysBlockedGroups.spotlightSearch}
                  setBlocked={(blocked) =>
                    patchConfig({
                      alwaysBlockedGroups: {
                        ...config.alwaysBlockedGroups,
                        spotlightSearch: blocked,
                      },
                    })
                  }
                />
              </Card>
            </SettingsRow>
            <SettingsRow
              type="alwaysOn"
              title="Custom Always Blocked Domains"
              description="These domains will be blocked at all times, even when the filter is suspended."
            >
              {config.customAlwaysBlockedDomains.length > 0 ? (
                <VStack gap={3}>
                  <HStack wrap gap={2}>
                    {config.customAlwaysBlockedDomains.map((domain) => (
                      <HStack
                        key={domain}
                        gap={2}
                        className="bg-white border p-1 pl-2.5 rounded-xl border-stone-200 shadow shadow-stone-300/30"
                      >
                        <BanIcon className="h-4 w-4 text-stone-500" />
                        <Text variant="body">{domain}</Text>
                        <Button
                          type="button"
                          onClick={() => {
                            patchConfig({
                              customAlwaysBlockedDomains:
                                config.customAlwaysBlockedDomains.filter(
                                  (currentDomain) => currentDomain !== domain,
                                ),
                            });
                          }}
                          icon={XIcon}
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
          </VStack>
        </PersonSettingsExpandableSection>
        <PersonSettingsExpandableSection
          title="Apps"
          defaultExpanded={defaultExpandedSections.includes(`apps`)}
          previewChips={[
            {
              title: `Blocked Apps`,
              values: [
                {
                  text: `${config.blockedApps.length}`,
                  color: config.blockedApps.length > 0 ? `violet` : `neutral`,
                },
              ],
            },
            {
              title: `Unrestricted Apps`,
              values: [
                {
                  text: `${config.unrestrictedApps.length}`,
                  color: config.unrestrictedApps.length > 0 ? `violet` : `neutral`,
                },
              ],
            },
          ]}
        >
          <VStack gap={3}>
            <SettingsRow
              type="alwaysOn"
              title="Blocked Apps"
              description="These apps can't open at all. Add a schedule to only block them at certain times."
            >
              {config.blockedApps.length > 0 ? (
                <VStack gap={3}>
                  {config.blockedApps.map((app, index) => (
                    <ConfiguredAppRow
                      key={`${app.nameOrBundleId}-${index}`}
                      app={app}
                      setSchedule={(schedule) =>
                        patchConfig({
                          blockedApps: config.blockedApps.map((blockedApp, appIndex) =>
                            appIndex === index ? { ...blockedApp, schedule } : blockedApp,
                          ),
                        })
                      }
                      onRemove={() =>
                        patchConfig({
                          blockedApps: config.blockedApps.filter(
                            (_app, appIndex) => appIndex !== index,
                          ),
                        })
                      }
                    />
                  ))}
                  <HStack justify="end">
                    <Button
                      type="button"
                      onClick={() => setAddAppSlideOverType(`blocked`)}
                      icon={PlusIcon}
                    >
                      Add Blocked App
                    </Button>
                  </HStack>
                </VStack>
              ) : (
                <EmptyState
                  icon={SquareDashedIcon}
                  title="No Blocked Apps"
                  description="Let's add some!"
                  button={{
                    text: `Add Blocked App`,
                    type: `button`,
                    onClick: () => setAddAppSlideOverType(`blocked`),
                    icon: PlusIcon,
                    variant: `primary`,
                  }}
                />
              )}
            </SettingsRow>
            <SettingsRow
              type="alwaysOn"
              title="Apps With Unrestricted Internet Access"
              description="By default apps can't reach the internet. These apps are granted full, unrestricted access."
            >
              {config.unrestrictedApps.length > 0 ? (
                <VStack gap={3}>
                  {config.unrestrictedApps.map((app, index) => (
                    <ConfiguredAppRow
                      key={`${app.nameOrBundleId}-${index}`}
                      app={app}
                      onRemove={() =>
                        patchConfig({
                          unrestrictedApps: config.unrestrictedApps.filter(
                            (_app, appIndex) => appIndex !== index,
                          ),
                        })
                      }
                    />
                  ))}
                  <HStack justify="end">
                    <Button
                      type="button"
                      onClick={() => setAddAppSlideOverType(`unrestricted`)}
                      icon={PlusIcon}
                    >
                      Add Unrestricted App
                    </Button>
                  </HStack>
                </VStack>
              ) : (
                <EmptyState
                  icon={SquareDashedIcon}
                  title="No Unrestricted Apps"
                  description="Let's add some!"
                  button={{
                    text: `Add Unrestricted App`,
                    type: `button`,
                    onClick: () => setAddAppSlideOverType(`unrestricted`),
                    icon: PlusIcon,
                    variant: `primary`,
                  }}
                />
              )}
            </SettingsRow>
          </VStack>
        </PersonSettingsExpandableSection>
      </CardContainer>
      <AddBlockedDomainModal
        open={addBlockedDomainModalOpen}
        onOpenChange={setAddBlockedDomainModalOpen}
        onAdd={addCustomAlwaysBlockedDomain}
      />
      <AddKeychainSlideOver
        open={addKeychainSlideOverOpen}
        onOpenChange={setAddKeychainSlideOverOpen}
        personName={personName}
        keychains={allKeychains}
        assignedKeychainIds={config.keychainIds}
        onAdd={addKeychains}
      />
      {addAppSlideOverType && (
        <AddMacAppSlideOver
          open
          type={addAppSlideOverType}
          personName={personName}
          installedApps={installedMacApps}
          blockedApps={config.blockedApps}
          unrestrictedApps={config.unrestrictedApps}
          onOpenChange={(open) => {
            if (!open) {
              setAddAppSlideOverType(null);
            }
          }}
          onAdd={(apps) => addSelectedInstalledApps(addAppSlideOverType, apps)}
        />
      )}
    </>
  );
};

export default MacSettingsPage;
