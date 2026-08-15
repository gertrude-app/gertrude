import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import React from 'react';
import type { LoadableState } from '#/components/types';
import type { InstalledMacApp, MacSettingsConfiguration } from './MacSettingsPage.types';
import PersonSettingsShellPage from '../people/PersonSettingsShellPage';
import MacSettingsPage from './MacSettingsPage';

const meta = {
  title: 'Account/Pages/People/Person Mac Settings',
  component: MacSettingsPage,
  parameters: { layout: 'fullscreen' },
};

export default meta;

interface MacSettingsStoryProps {
  initialState: LoadableState<MacSettingsConfiguration>;
  savingMonitoring?: boolean;
}

const defaultSettings: MacSettingsConfiguration = {
  keyloggingEnabled: true,
  showSuspensionActivity: true,
  screenshots: {
    enabled: true,
    resolution: 1080,
    frequency: 120,
    canBeDisabled: true,
  },
  internetFiltering: {
    enabled: true,
    canBeDisabled: true,
    downtime: {
      start: { hour: 21, minute: 0 },
      end: { hour: 5, minute: 0 },
    },
    keychains: [
      {
        id: `family`,
        name: `Family`,
        description: `Everyday websites and services.`,
        isPublic: false,
        isOwn: true,
        numKeys: 42,
        schedule: {
          type: `active`,
          days: {
            sunday: false,
            monday: true,
            tuesday: true,
            wednesday: true,
            thursday: true,
            friday: true,
            saturday: false,
          },
          startTime: { hour: 8, minute: 0 },
          endTime: { hour: 16, minute: 0 },
        },
      },
    ],
    supportsAlwaysBlocked: true,
    availableAlwaysBlockedGroups: [
      {
        id: `adult-content`,
        name: `Adult Content`,
        description: `Block the most-trafficked adult websites, plus adult-oriented TLDs.`,
        longDescription: `Blocks roughly 50 of the most-trafficked adult sites by current web traffic, plus adult-oriented top-level domains.`,
      },
      {
        id: `messages-gif-search`,
        name: `Messages GIF Search`,
        description: `Block the #images GIF picker in Messages and common GIF providers.`,
        longDescription: `Prevents access to the #images GIF picker in Messages, plus major GIF content providers.`,
      },
      {
        id: `social-media`,
        name: `Social Media`,
        description: `Block the most prominent social media sites.`,
        longDescription: `Blocks Instagram, TikTok, X, Facebook, Snapchat, Threads, and Pinterest.`,
      },
      {
        id: `spotlight-search`,
        name: `Spotlight Search`,
        description: `Block web results in macOS Spotlight search.`,
        longDescription: `Blocks Spotlight's web-backed results, including Siri Suggestions and web images.`,
      },
    ],
    alwaysBlockedGroupIds: [`adult-content`, `messages-gif-search`, `spotlight-search`],
    customAlwaysBlockedRules: [
      {
        id: `rule-reddit`,
        rule: { case: `hostnameOrSubdomain`, value: `reddit.com` },
      },
      {
        id: `rule-discord`,
        rule: { case: `hostnameOrSubdomain`, value: `discord.com` },
      },
    ],
    availableKeychains: [
      {
        id: `family`,
        name: `Family`,
        description: `Everyday websites and services.`,
        isPublic: false,
        isOwn: true,
        numKeys: 42,
      },
      {
        id: `school`,
        name: `School`,
        description: `Educational resources and research.`,
        isPublic: true,
        isOwn: false,
        numKeys: 18,
      },
    ],
  },
  apps: {
    blocked: [
      {
        id: `blocked-minecraft`,
        identifier: `com.mojang.minecraftlauncher`,
        schedule: {
          type: `inactive`,
          days: {
            sunday: false,
            monday: true,
            tuesday: true,
            wednesday: true,
            thursday: true,
            friday: true,
            saturday: false,
          },
          startTime: { hour: 8, minute: 0 },
          endTime: { hour: 16, minute: 0 },
        },
      },
      {
        id: `blocked-discord`,
        identifier: `com.hnc.Discord`,
      },
    ],
    unrestricted: [
      {
        id: `unrestricted-scratch`,
        scope: { type: `bundleId`, bundleId: `edu.mit.scratch` },
        schedule: {
          type: `active`,
          days: {
            sunday: false,
            monday: true,
            tuesday: true,
            wednesday: true,
            thursday: true,
            friday: true,
            saturday: false,
          },
          startTime: { hour: 8, minute: 0 },
          endTime: { hour: 16, minute: 0 },
        },
      },
    ],
    publicUnrestricted: [
      {
        keychainId: `school`,
        keychainName: `School`,
        scope: { type: `identifiedAppSlug`, identifiedAppSlug: `chrome` },
      },
    ],
  },
  hasMacDevices: true,
};

const installedApps: InstalledMacApp[] = [
  {
    id: `minecraft`,
    name: `Minecraft`,
    bundleId: `com.mojang.minecraftlauncher`,
    appIconUrl: `/example-app-icons/minecraft.webp`,
  },
  {
    id: `discord`,
    name: `Discord`,
    bundleId: `com.hnc.Discord`,
    appIconUrl: `/example-app-icons/discord.webp`,
  },
  {
    id: `scratch`,
    name: `Scratch`,
    bundleId: `edu.mit.scratch`,
    appIconUrl: `/example-app-icons/scratch.webp`,
  },
  {
    id: `chrome`,
    name: `Google Chrome`,
    bundleId: `com.google.Chrome`,
    identifiedAppSlug: `chrome`,
    appIconUrl: `/example-app-icons/chrome.webp`,
  },
];

const expandSection = (canvasElement: HTMLElement, title: string): void => {
  const button = Array.from(canvasElement.querySelectorAll(`button`)).find(
    (element) => element.getAttribute(`aria-label`) === title,
  );
  if (!button) {
    throw new globalThis.Error(`${title} section not found`);
  }
  button.click();
};

const MacSettingsStory: React.FC<MacSettingsStoryProps> = ({
  initialState,
  savingMonitoring,
}) => {
  const [state, setState] = React.useState(initialState);

  return (
    <StoryScreen>
      <PersonSettingsShellPage
        personName="Jude"
        peopleHref="/people"
        baseHref="/people/person-1"
        selectedHref="/people/person-1/mac-settings"
      >
        <MacSettingsPage
          state={state}
          installedApps={installedApps}
          savingMonitoring={savingMonitoring}
          onRequestPublicKeychain={async () => {}}
          onSaveMonitoring={(configuration) => {
            if (state.status === `success`) {
              setState({
                status: `success`,
                data: {
                  ...state.data,
                  keyloggingEnabled: configuration.keyloggingEnabled,
                  showSuspensionActivity: configuration.showSuspensionActivity,
                  screenshots: {
                    ...state.data.screenshots,
                    ...configuration.screenshots,
                  },
                },
              });
            }
          }}
          onSaveApps={({ blockedApps, unrestrictedApps }) => {
            if (state.status === `success`) {
              setState({
                status: `success`,
                data: {
                  ...state.data,
                  apps: {
                    ...state.data.apps,
                    blocked: blockedApps,
                    unrestricted: unrestrictedApps,
                  },
                },
              });
            }
          }}
          onSaveInternetFiltering={({
            filteringEnabled,
            downtime,
            keychains,
            alwaysBlockedGroupIds,
            customAlwaysBlockedRules,
          }) => {
            if (state.status === `success`) {
              setState({
                status: `success`,
                data: {
                  ...state.data,
                  internetFiltering: {
                    ...state.data.internetFiltering,
                    enabled: filteringEnabled,
                    downtime,
                    alwaysBlockedGroupIds,
                    customAlwaysBlockedRules,
                    keychains: keychains.map((keychain) => ({
                      ...state.data.internetFiltering.availableKeychains.find(
                        (availableKeychain) => availableKeychain.id === keychain.id,
                      )!,
                      schedule: keychain.schedule,
                    })),
                  },
                },
              });
            }
          }}
        />
      </PersonSettingsShellPage>
    </StoryScreen>
  );
};

export const Overview = {
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <MacSettingsStory initialState={{ status: `success`, data: defaultSettings }} />
  ),
};

export const Monitoring = {
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <MacSettingsStory initialState={{ status: `success`, data: defaultSettings }} />
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) => {
    expandSection(canvasElement, `Monitoring`);
  },
};

export const InternetFiltering = {
  name: 'Internet filtering',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <MacSettingsStory initialState={{ status: `success`, data: defaultSettings }} />
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) => {
    expandSection(canvasElement, `Internet Filtering`);
  },
};

export const Apps = {
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <MacSettingsStory initialState={{ status: `success`, data: defaultSettings }} />
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) => {
    expandSection(canvasElement, `Apps`);
  },
};

export const NoBlockedApps = {
  name: 'No blocked apps',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <MacSettingsStory
      initialState={{
        status: `success`,
        data: {
          ...defaultSettings,
          apps: { ...defaultSettings.apps, blocked: [] },
        },
      }}
    />
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) => {
    expandSection(canvasElement, `Apps`);
  },
};

export const NoUnrestrictedApps = {
  name: 'No unrestricted apps',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <MacSettingsStory
      initialState={{
        status: `success`,
        data: {
          ...defaultSettings,
          apps: { ...defaultSettings.apps, unrestricted: [] },
        },
      }}
    />
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) => {
    expandSection(canvasElement, `Apps`);
  },
};

export const NoDowntime = {
  name: 'No downtime',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <MacSettingsStory
      initialState={{
        status: `success`,
        data: {
          ...defaultSettings,
          internetFiltering: {
            ...defaultSettings.internetFiltering,
            downtime: undefined,
          },
        },
      }}
    />
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) => {
    expandSection(canvasElement, `Internet Filtering`);
  },
};

export const CustomRuleVariants = {
  name: 'Custom rule variants',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <MacSettingsStory
      initialState={{
        status: `success`,
        data: {
          ...defaultSettings,
          internetFiltering: {
            ...defaultSettings.internetFiltering,
            customAlwaysBlockedRules: [
              {
                id: `rule-reddit`,
                rule: { case: `hostnameOrSubdomain`, value: `Reddit.COM` },
                comment: `Retained legacy comment`,
              },
              {
                id: `rule-app`,
                rule: { case: `bundleIdContains`, value: `com.spotify.client` },
                comment: `Legacy app rule`,
              },
              {
                id: `rule-browser`,
                rule: {
                  case: `both`,
                  a: { case: `hostnameContains`, value: `images.example` },
                  b: { case: `flowTypeIs`, value: `browser` },
                },
              },
            ],
          },
        },
      }}
    />
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) => {
    expandSection(canvasElement, `Internet Filtering`);
  },
};

export const UnsavedChanges = {
  name: 'Unsaved changes',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <MacSettingsStory initialState={{ status: `success`, data: defaultSettings }} />
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) => {
    const toggle = canvasElement.querySelector<HTMLButtonElement>(
      `[role="switch"][aria-label="Enable Keylogging"]`,
    );
    if (!toggle) {
      throw new globalThis.Error(`Enable Keylogging toggle not found`);
    }
    toggle.click();
    toggle.blur();
  },
};

export const NoAlwaysBlockedSelections = {
  name: 'No Always Blocked selections',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <MacSettingsStory
      initialState={{
        status: `success`,
        data: {
          ...defaultSettings,
          internetFiltering: {
            ...defaultSettings.internetFiltering,
            alwaysBlockedGroupIds: [],
            customAlwaysBlockedRules: [],
          },
        },
      }}
    />
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) => {
    expandSection(canvasElement, `Internet Filtering`);
  },
};

export const NoAssignedKeychains = {
  name: 'No assigned keychains',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <MacSettingsStory
      initialState={{
        status: `success`,
        data: {
          ...defaultSettings,
          internetFiltering: {
            ...defaultSettings.internetFiltering,
            keychains: [],
          },
        },
      }}
    />
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) => {
    expandSection(canvasElement, `Internet Filtering`);
  },
};

export const AlwaysBlockedUnsupported = {
  name: 'Always Blocked unsupported',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <MacSettingsStory
      initialState={{
        status: `success`,
        data: {
          ...defaultSettings,
          internetFiltering: {
            ...defaultSettings.internetFiltering,
            supportsAlwaysBlocked: false,
          },
        },
      }}
    />
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) => {
    expandSection(canvasElement, `Internet Filtering`);
  },
};

export const FilteringRequiresUpdate = {
  name: 'Internet filtering requires Mac update',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <MacSettingsStory
      initialState={{
        status: `success`,
        data: {
          ...defaultSettings,
          internetFiltering: {
            ...defaultSettings.internetFiltering,
            canBeDisabled: false,
          },
        },
      }}
    />
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) => {
    expandSection(canvasElement, `Internet Filtering`);
  },
};

export const FilteringDisabled = {
  name: 'Internet filtering disabled',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <MacSettingsStory
      initialState={{
        status: `success`,
        data: {
          ...defaultSettings,
          internetFiltering: { ...defaultSettings.internetFiltering, enabled: false },
        },
      }}
    />
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) => {
    expandSection(canvasElement, `Internet Filtering`);
  },
};

export const ScreenshotsRequired = {
  name: 'Screenshots required while filtering is disabled',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <MacSettingsStory
      initialState={{
        status: `success`,
        data: {
          ...defaultSettings,
          screenshots: { ...defaultSettings.screenshots, canBeDisabled: false },
          internetFiltering: { ...defaultSettings.internetFiltering, enabled: false },
        },
      }}
    />
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) => {
    expandSection(canvasElement, `Monitoring`);
  },
};

export const Loading = {
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => <MacSettingsStory initialState={{ status: `loading` }} />,
};

export const Error = {
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <MacSettingsStory
      initialState={{
        status: `error`,
        message: `Check your connection and try again.`,
        onRetry: () => {},
      }}
    />
  ),
};

export const NoConnectedMac = {
  name: 'No connected Mac',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <MacSettingsStory
      initialState={{
        status: `success`,
        data: { ...defaultSettings, hasMacDevices: false },
      }}
    />
  ),
};
