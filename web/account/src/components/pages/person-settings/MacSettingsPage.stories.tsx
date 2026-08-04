import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import React from 'react';
import type { LoadableState } from '#/components/types';
import PersonSettingsShellPage from '../people/PersonSettingsShellPage';
import MacSettingsPage, { type MacSettingsConfiguration } from './MacSettingsPage';

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
    keychains: [
      {
        id: `family`,
        name: `Family`,
        description: `Everyday websites and services.`,
        isPublic: false,
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
    customAlwaysBlockedDomains: [`reddit.com`, `discord.com`],
    availableKeychains: [
      {
        id: `family`,
        name: `Family`,
        description: `Everyday websites and services.`,
        isPublic: false,
        numKeys: 42,
      },
      {
        id: `school`,
        name: `School`,
        description: `Educational resources and research.`,
        isPublic: true,
        numKeys: 18,
      },
    ],
  },
  hasMacDevices: true,
};

const expandSection = (canvasElement: HTMLElement, title: string): void => {
  const heading = Array.from(canvasElement.querySelectorAll(`h2`)).find(
    (element) => element.textContent === title,
  );
  const header = heading?.parentElement?.parentElement;
  if (!header) {
    throw new globalThis.Error(`${title} section not found`);
  }
  header.click();
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
          savingMonitoring={savingMonitoring}
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
          onSaveInternetFiltering={({
            filteringEnabled,
            keychains,
            alwaysBlockedGroupIds,
            customAlwaysBlockedDomains,
          }) => {
            if (state.status === `success`) {
              setState({
                status: `success`,
                data: {
                  ...state.data,
                  internetFiltering: {
                    ...state.data.internetFiltering,
                    enabled: filteringEnabled,
                    alwaysBlockedGroupIds,
                    customAlwaysBlockedDomains,
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

export const ScreenshotsRequired = {
  name: 'Screenshots required while filtering is disabled',
  parameters: { ...galleryParameters, screenshotsAt: ['desktop'] },
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
