import {
  Button,
  DropdownMenu,
  DropdownMenuItem,
  EmptyState,
  Input,
  SlideOver,
  Tooltip,
} from '@gertrude/ui';
import { createFileRoute } from '@tanstack/react-router';
import cx from 'clsx';
import {
  BanIcon,
  CheckIcon,
  EllipsisIcon,
  KeyIcon,
  PlusIcon,
  SquareDashedIcon,
  TrashIcon,
  XIcon,
} from 'lucide-react';
import React, { useState } from 'react';
import CardContainer from '#/components/CardContainer';
import AddBlockedDomainModal from '#/components/person-settings/AddBlockedDomainModal';
import AddKeychainSlideOver from '#/components/person-settings/AddKeychainSlideOver';
import BlockGroup from '#/components/person-settings/BlockGroup';
import KeychainCard from '#/components/person-settings/KeychainCard';
import PersonSettingsExpandableSection from '#/components/person-settings/PersonSettingsExpandableSection';
import ScheduleButton, {
  ScheduleEditor,
} from '#/components/person-settings/ScheduleButton';
import SettingsRow from '#/components/person-settings/SettingsRow';
import {
  type InstalledMacApp,
  type PersonMacSettingsConfiguration,
  type TimeOfDay,
  getPersonMacSettingsPage,
  useMockData,
} from '#/lib/mock';
import { formatSchedule, formatTime } from '#/lib/utils';

type AddAppSlideOverType = `blocked` | `unrestricted`;

type ConfiguredAppReference = {
  nameOrBundleId: string;
};

const defaultDowntime: NonNullable<PersonMacSettingsConfiguration[`downtime`]> = {
  start: { hour: 9, minute: 0 },
  end: { hour: 17, minute: 0 },
};

const timeOfDayToInputValue = (time: TimeOfDay): string =>
  `${`${time.hour}`.padStart(2, `0`)}:${`${time.minute}`.padStart(2, `0`)}`;

const configuredAppMatchesInstalledApp = (
  configuredApp: ConfiguredAppReference,
  installedApp: InstalledMacApp,
): boolean =>
  configuredApp.nameOrBundleId === installedApp.name ||
  configuredApp.nameOrBundleId === installedApp.bundleId;

const inputValueToTimeOfDay = (value: string): TimeOfDay | null => {
  const [hourString, minuteString] = value.split(`:`);

  if (hourString === undefined || minuteString === undefined) {
    return null;
  }

  const hour = Number(hourString);
  const minute = Number(minuteString);

  if (
    !Number.isInteger(hour) ||
    !Number.isInteger(minute) ||
    hour < 0 ||
    hour > 23 ||
    minute < 0 ||
    minute > 59
  ) {
    return null;
  }

  return { hour, minute };
};

const MacSettingsPage: React.FC = () => {
  const { personId } = Route.useParams();
  const [addBlockedDomainModalOpen, setAddBlockedDomainModalOpen] = useState(false);
  const [addKeychainSlideOverOpen, setAddKeychainSlideOverOpen] = useState(false);
  const [addAppSlideOverType, setAddAppSlideOverType] =
    useState<AddAppSlideOverType | null>(null);
  const [selectedInstalledAppIds, setSelectedInstalledAppIds] = useState<string[]>([]);
  const { db, dispatch } = useMockData();
  const { config, installedMacApps, keychains, macDevices, personName } =
    getPersonMacSettingsPage(db, personId);
  const patchConfig = (patch: Partial<PersonMacSettingsConfiguration>): void => {
    dispatch({ type: `macSettings.patch`, personId, patch });
  };
  const patchDowntime = (
    patch: Partial<NonNullable<PersonMacSettingsConfiguration[`downtime`]>>,
  ): void => {
    patchConfig({ downtime: { ...(config?.downtime ?? defaultDowntime), ...patch } });
  };

  if (!config || macDevices.length === 0) {
    return (
      <CardContainer className="flex flex-col gap-4">
        <span className="text-center text-sm text-stone-500">
          No Mac settings to configure.
        </span>
      </CardContainer>
    );
  }

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
  const selectedInstalledApps = installedMacApps.filter((app) =>
    selectedInstalledAppIds.includes(app.id),
  );
  const getInstalledAppConfigurationType = (
    app: InstalledMacApp,
  ): AddAppSlideOverType | null => {
    if (
      config.blockedApps.some((configuredApp) =>
        configuredAppMatchesInstalledApp(configuredApp, app),
      )
    ) {
      return `blocked`;
    }

    if (
      config.unrestrictedApps.some((configuredApp) =>
        configuredAppMatchesInstalledApp(configuredApp, app),
      )
    ) {
      return `unrestricted`;
    }

    return null;
  };
  const openAddAppSlideOver = (type: AddAppSlideOverType): void => {
    setSelectedInstalledAppIds([]);
    setAddAppSlideOverType(type);
  };
  const closeAddAppSlideOver = (): void => {
    setAddAppSlideOverType(null);
    setSelectedInstalledAppIds([]);
  };
  const toggleSelectedInstalledApp = (app: InstalledMacApp): void => {
    if (getInstalledAppConfigurationType(app)) {
      return;
    }

    setSelectedInstalledAppIds((currentIds) =>
      currentIds.includes(app.id)
        ? currentIds.filter((id) => id !== app.id)
        : [...currentIds, app.id],
    );
  };
  const addSelectedInstalledApps = (): void => {
    const appsToAdd = selectedInstalledApps.map((app) => ({
      nameOrBundleId: app.name,
      appIconUrl: app.appIconUrl,
    }));

    if (!addAppSlideOverType || appsToAdd.length === 0) {
      return;
    }

    if (addAppSlideOverType === `blocked`) {
      patchConfig({ blockedApps: [...config.blockedApps, ...appsToAdd] });
    } else {
      patchConfig({ unrestrictedApps: [...config.unrestrictedApps, ...appsToAdd] });
    }

    closeAddAppSlideOver();
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
          <div className="flex flex-col gap-3">
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
              <div className="flex flex-col @lg/main:flex-row gap-4 @lg/main:gap-2">
                <Input
                  label="Average Frequency"
                  suffix="seconds"
                  prefix="Every"
                  type="number"
                  value={String(config.screenshots?.frequency || 0)}
                  setValue={() => {}}
                  helperText="The actual frequency will be randomized around the average you provide."
                  className="@lg/main:w-1/2"
                />
                <Input
                  label="Resolution"
                  suffix="px"
                  type="number"
                  value={String(config.screenshots?.resolution || 0)}
                  setValue={() => {}}
                  className="@lg/main:w-1/2"
                />
              </div>
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
          </div>
        </PersonSettingsExpandableSection>
        <PersonSettingsExpandableSection
          title="Internet Filtering"
          previewChips={[
            config.downtime
              ? {
                  title: `Downtime`,
                  values: [
                    {
                      text: `${formatTime(config.downtime.start)} – ${formatTime(
                        config.downtime.end,
                      )}`,
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
          <div className="flex flex-col gap-3">
            <SettingsRow
              type="toggle"
              title="Enable Downtime"
              description="Completely restrict all internet access during specified hours"
              enabled={config.downtime !== undefined}
              setEnabled={(enabled) =>
                patchConfig({ downtime: enabled ? defaultDowntime : undefined })
              }
            >
              <div className="flex gap-2">
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
              </div>
            </SettingsRow>
            <SettingsRow
              type="toggle"
              title="Filter Internet Access"
              description="Block all internet access except sites allowed by assigned keychains"
              enabled={config.filteringOn}
              setEnabled={(enabled) => patchConfig({ filteringOn: enabled })}
            >
              {keychains.length > 0 ? (
                <div className="flex flex-col gap-3">
                  <div className="grid grid-cols-1 gap-3 @4xl/main:grid-cols-2 @6xl/main:grid-cols-3">
                    {keychains.map((keychain) => (
                      <KeychainCard
                        key={keychain.id}
                        keychainId={keychain.id}
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
                  <div className="flex justify-end items-center">
                    <Button
                      type="button"
                      onClick={() => setAddKeychainSlideOverOpen(true)}
                      icon={PlusIcon}
                    >
                      Add Keychain
                    </Button>
                  </div>
                </div>
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
              <div className="bg-white border border-stone-200 rounded-xl shadow shadow-stone-300/30 flex flex-col overflow-hidden">
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
              </div>
            </SettingsRow>
            <SettingsRow
              type="alwaysOn"
              title="Custom Always Blocked Domains"
              description="These domains will be blocked at all times, even when the filter is suspended."
            >
              {config.customAlwaysBlockedDomains.length > 0 ? (
                <div className="flex flex-col gap-3">
                  <div className="flex flex-wrap gap-2">
                    {config.customAlwaysBlockedDomains.map((domain) => (
                      <div
                        key={domain}
                        className="bg-white flex items-center gap-2 border p-1 pl-2.5 rounded-xl border-stone-200 shadow shadow-stone-300/30"
                      >
                        <BanIcon className="h-4 w-4 text-stone-500" />
                        <span className="text-stone-800">{domain}</span>
                        <Button
                          type="button"
                          onClick={() => {
                            patchConfig({
                              customAlwaysBlockedDomains:
                                config.customAlwaysBlockedDomains.filter(
                                  (d) => d !== domain,
                                ),
                            });
                          }}
                          icon={XIcon}
                          size="small"
                          variant="ghost"
                        />
                      </div>
                    ))}
                  </div>
                  <div className="flex justify-end">
                    <Button
                      type="button"
                      onClick={() => setAddBlockedDomainModalOpen(true)}
                      icon={PlusIcon}
                    >
                      Add Blocked Domain
                    </Button>
                  </div>
                </div>
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
          </div>
        </PersonSettingsExpandableSection>
        <PersonSettingsExpandableSection
          title="Apps"
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
          <div className="flex flex-col gap-3">
            <SettingsRow
              type="alwaysOn"
              title="Blocked Apps"
              description="These apps can't open at all. Add a schedule to only block them at certain times."
            >
              {config.blockedApps.length > 0 ? (
                <div className="flex flex-col gap-3">
                  {config.blockedApps.map((app, index) => (
                    <div
                      key={`${app.nameOrBundleId}-${index}`}
                      className="flex items-center justify-between border gap-2 p-3 rounded-xl border-stone-200 shadow shadow-stone-300/30 bg-white"
                    >
                      <div className="flex items-center gap-3">
                        <div className="shrink-0">
                          <img
                            src={app.appIconUrl}
                            alt=""
                            className="w-10 h-10 absolute blur-xs opacity-50"
                          />
                          <img
                            src={app.appIconUrl}
                            alt=""
                            className="w-10 h-10 shadow rounded-[11px] relative"
                          />
                        </div>
                        <div className="flex flex-col">
                          <span className="font-medium text-stone-800">
                            {app.nameOrBundleId}
                          </span>
                          {app.schedule && (
                            <span className="text-xs text-stone-600 -mt-0.25">
                              {formatSchedule(app.schedule)}
                            </span>
                          )}
                        </div>
                      </div>
                      <div className="hidden items-center gap-2 sm:flex">
                        <ScheduleButton
                          schedule={app.schedule}
                          setSchedule={(schedule) =>
                            patchConfig({
                              blockedApps: config.blockedApps.map(
                                (blockedApp, appIndex) =>
                                  appIndex === index
                                    ? { ...blockedApp, schedule }
                                    : blockedApp,
                              ),
                            })
                          }
                        />
                        <Button
                          type="button"
                          ariaLabel={`Remove ${app.nameOrBundleId}`}
                          onClick={() =>
                            patchConfig({
                              blockedApps: config.blockedApps.filter(
                                (_app, appIndex) => appIndex !== index,
                              ),
                            })
                          }
                          icon={XIcon}
                          size="small"
                          variant="ghost"
                        />
                      </div>
                      <div className="sm:hidden">
                        <DropdownMenu
                          contentClassName="w-82"
                          trigger={
                            <Button
                              type="button"
                              ariaLabel={`More actions for ${app.nameOrBundleId}`}
                              onClick={() => {}}
                              icon={EllipsisIcon}
                              size="small"
                            />
                          }
                        >
                          <ScheduleEditor
                            schedule={app.schedule}
                            setSchedule={(schedule) =>
                              patchConfig({
                                blockedApps: config.blockedApps.map(
                                  (blockedApp, appIndex) =>
                                    appIndex === index
                                      ? { ...blockedApp, schedule }
                                      : blockedApp,
                                ),
                              })
                            }
                          />
                          <div className="mx-1 border-t border-stone-200 pt-1">
                            <DropdownMenuItem
                              title="Remove App"
                              icon={TrashIcon}
                              onSelect={() =>
                                patchConfig({
                                  blockedApps: config.blockedApps.filter(
                                    (_app, appIndex) => appIndex !== index,
                                  ),
                                })
                              }
                              destructive
                            />
                          </div>
                        </DropdownMenu>
                      </div>
                    </div>
                  ))}
                  <div className="flex justify-end">
                    <Button
                      type="button"
                      onClick={() => openAddAppSlideOver(`blocked`)}
                      icon={PlusIcon}
                    >
                      Add Blocked App
                    </Button>
                  </div>
                </div>
              ) : (
                <EmptyState
                  icon={SquareDashedIcon}
                  title="No Blocked Apps"
                  description="Let's add some!"
                  button={{
                    text: `Add Blocked App`,
                    type: `button`,
                    onClick: () => openAddAppSlideOver(`blocked`),
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
                <div className="flex flex-col gap-3">
                  {config.unrestrictedApps.map((app, index) => (
                    <div
                      key={`${app.nameOrBundleId}-${index}`}
                      className="flex items-center justify-between border p-3 rounded-xl border-stone-200 shadow shadow-stone-300/30 bg-white"
                    >
                      <div className="flex items-center gap-3">
                        <div className="shrink-0">
                          <img
                            src={app.appIconUrl}
                            alt=""
                            className="w-10 h-10 absolute blur-xs opacity-50"
                          />
                          <img
                            src={app.appIconUrl}
                            alt=""
                            className="w-10 h-10 shadow rounded-[11px] relative"
                          />
                        </div>
                        <span className="font-medium text-stone-800">
                          {app.nameOrBundleId}
                        </span>
                      </div>
                      <Button
                        type="button"
                        ariaLabel={`Remove ${app.nameOrBundleId}`}
                        onClick={() =>
                          patchConfig({
                            unrestrictedApps: config.unrestrictedApps.filter(
                              (_app, appIndex) => appIndex !== index,
                            ),
                          })
                        }
                        icon={XIcon}
                        size="small"
                        variant="ghost"
                      />
                    </div>
                  ))}
                  <div className="flex justify-end">
                    <Button
                      type="button"
                      onClick={() => openAddAppSlideOver(`unrestricted`)}
                      icon={PlusIcon}
                    >
                      Add Unrestricted App
                    </Button>
                  </div>
                </div>
              ) : (
                <EmptyState
                  icon={SquareDashedIcon}
                  title="No Unrestricted Apps"
                  description="Let's add some!"
                  button={{
                    text: `Add Unrestricted App`,
                    type: `button`,
                    onClick: () => openAddAppSlideOver(`unrestricted`),
                    icon: PlusIcon,
                    variant: `primary`,
                  }}
                />
              )}
            </SettingsRow>
          </div>
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
        keychains={db.keychains}
        assignedKeychainIds={config.keychainIds}
        onAdd={addKeychains}
      />
      <SlideOver
        open={addAppSlideOverType !== null}
        onOpenChange={(open) => {
          if (!open) {
            closeAddAppSlideOver();
          }
        }}
        ariaLabel={
          addAppSlideOverType === `unrestricted`
            ? `Add unrestricted apps`
            : `Add blocked apps`
        }
        heading={
          addAppSlideOverType === `unrestricted`
            ? `Add unrestricted apps`
            : `Add blocked apps`
        }
        subheading={`Choose one or more apps installed on ${personName}'s Mac.`}
        size="large"
      >
        <div className="flex h-full flex-col">
          <div className="min-h-0 flex-1 overflow-y-auto px-3 pb-4 @lg/slide:px-6">
            <div className="grid grid-cols-2 gap-2 @md/slide:grid-cols-3">
              {installedMacApps.map((app) => {
                const selected = selectedInstalledAppIds.includes(app.id);
                const configurationType = getInstalledAppConfigurationType(app);
                const disabled = configurationType !== null;
                const disabledLabel =
                  configurationType === addAppSlideOverType
                    ? `Already added`
                    : configurationType === `blocked`
                      ? `Blocked`
                      : configurationType === `unrestricted`
                        ? `Unrestricted`
                        : null;
                const disabledTooltip =
                  configurationType === addAppSlideOverType
                    ? addAppSlideOverType === `blocked`
                      ? `This app is already in Blocked Apps.`
                      : `This app is already in Unrestricted Apps.`
                    : configurationType === `blocked`
                      ? `Remove this app from Blocked Apps before adding it to Unrestricted Apps.`
                      : configurationType === `unrestricted`
                        ? `Remove this app from Unrestricted Apps before adding it to Blocked Apps.`
                        : null;
                const appButton = (
                  <button
                    key={app.id}
                    type="button"
                    disabled={disabled}
                    aria-pressed={selected}
                    onClick={() => toggleSelectedInstalledApp(app)}
                    className={cx(
                      `group relative flex min-h-34 w-full flex-col items-center justify-center rounded-xl border p-3 text-center shadow transition-[background-color,border-color,box-shadow,opacity] duration-150`,
                      disabled
                        ? `cursor-not-allowed border-stone-200 bg-stone-100/70 opacity-60 shadow-transparent`
                        : selected
                          ? `cursor-pointer border-violet-300 bg-violet-50 shadow-violet-300/30 hover:border-violet-400 hover:shadow-violet-300/50`
                          : `cursor-pointer border-stone-200 bg-white shadow-stone-300/30 hover:border-stone-400/70 hover:shadow-stone-300/70`,
                    )}
                  >
                    <div className="relative mb-2">
                      <img
                        src={app.appIconUrl}
                        alt=""
                        className="w-10 h-10 absolute blur-xs opacity-50"
                      />
                      <img
                        src={app.appIconUrl}
                        alt=""
                        className="w-10 h-10 shadow rounded-[11px] relative"
                      />
                      {selected && !disabled && (
                        <span className="absolute -right-1 -top-1 flex h-5 w-5 items-center justify-center rounded-full border border-violet-200 bg-violet-500 text-white shadow shadow-violet-500/30">
                          <CheckIcon className="h-3 w-3" strokeWidth={3} />
                        </span>
                      )}
                    </div>
                    <span className="text-sm font-medium text-stone-800">{app.name}</span>
                    <span className="mt-0.5 max-w-full truncate text-xs text-stone-500">
                      {app.bundleId}
                    </span>
                    {disabledLabel && (
                      <span className="mt-2 rounded-full bg-stone-200 px-2 py-0.5 text-xs font-medium text-stone-600">
                        {disabledLabel}
                      </span>
                    )}
                  </button>
                );

                return disabledTooltip ? (
                  <Tooltip key={app.id} content={disabledTooltip} side="top">
                    <span className="block h-full">{appButton}</span>
                  </Tooltip>
                ) : (
                  appButton
                );
              })}
            </div>
          </div>
          <div className="flex shrink-0 items-center justify-between gap-3 border-t border-stone-200 bg-stone-50/95 px-3 py-3 @lg/slide:px-6 @lg/slide:py-4">
            <span className="text-sm text-stone-600">
              {selectedInstalledApps.length === 0
                ? `Select one or more apps`
                : `${selectedInstalledApps.length} app${
                    selectedInstalledApps.length === 1 ? `` : `s`
                  } selected`}
            </span>
            <Button
              type="button"
              variant="primary"
              disabled={selectedInstalledApps.length === 0}
              onClick={addSelectedInstalledApps}
            >
              {selectedInstalledApps.length === 0
                ? addAppSlideOverType === `unrestricted`
                  ? `Add to Unrestricted Apps`
                  : `Add to Blocked Apps`
                : addAppSlideOverType === `unrestricted`
                  ? `Add ${selectedInstalledApps.length} App${
                      selectedInstalledApps.length === 1 ? `` : `s`
                    } to Unrestricted Apps`
                  : `Add ${selectedInstalledApps.length} App${
                      selectedInstalledApps.length === 1 ? `` : `s`
                    } to Blocked Apps`}
            </Button>
          </div>
        </div>
      </SlideOver>
    </>
  );
};

export const Route = createFileRoute(`/_app/people/$personId/mac-settings`)({
  component: MacSettingsPage,
});
