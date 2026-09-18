import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import React from 'react';
import type { ConnectedIOSApp } from '#/components/devices/types';
import type { MusicDeviceConnection } from '#/components/person-settings/MusicSection';
import type { Device } from '#/components/types';
import type { IosDeviceSettingsConfiguration } from './IosSettingsPage.types';
import PersonSettingsShellPage from '../people/PersonSettingsShellPage';
import IosDeviceSettingsSection from './IosDeviceSettingsSection';
import IosPersonSettingsPage from './IosPersonSettingsPage';
import IosSettingsPage from './IosSettingsPage';
import {
  iosDeviceSettingsAllAppsConnected,
  iosDeviceSettingsMusicTrial,
  iosDeviceSettingsMusicUnavailable,
  iosDeviceSettingsNoBlocker,
  iosDeviceSettingsPodcastsExpiring,
  iosDeviceSettingsPodcastsPaused,
  iosDeviceSettingsPodcastsTrial,
  iosDeviceSettingsUnsupervised,
  iosDeviceSettingsWithPodcasts,
  ipadDevice,
  iphoneDevice,
} from '#/components/storybook/fixtures';

const meta = {
  title: 'Account/Pages/People/Person Settings',
  parameters: { layout: 'fullscreen' },
};

export default meta;

type IOSDevice = Extract<Device, { type: `iphone` | `ipad` }>;

interface DeviceStorySettings {
  device: IOSDevice;
  settings: IosDeviceSettingsConfiguration;
}

const InPageContext: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <StoryScreen>
    <PersonSettingsShellPage
      personName="Jude"
      peopleHref="/people"
      baseHref="/people/person-1"
      selectedHref="/people/person-1/ios-settings"
    >
      {children}
    </PersonSettingsShellPage>
  </StoryScreen>
);

const settingsForDevice = (
  device: IOSDevice,
  settings: IosDeviceSettingsConfiguration,
): IosDeviceSettingsConfiguration => ({
  ...settings,
  deviceId: device.id,
  deviceName: device.modelName,
  modelIdentifier: device.modelIdentifier,
  iosVersion: device.iOSVersion,
});

const DeviceSettings: React.FC<{
  settings: IosDeviceSettingsConfiguration;
  defaultExpandedSection?: ConnectedIOSApp;
}> = ({ settings, defaultExpandedSection }) => (
  <IosSettingsPage
    state={{ status: `success`, data: settings }}
    defaultExpandedSection={defaultExpandedSection}
    onSaveBlockedGroups={() => {}}
    onSaveProfile={() => {}}
    onRequestPodcastsPinReset={() => Promise.resolve(481_920)}
  />
);

const IosOverview: React.FC<{
  devices: DeviceStorySettings[];
  defaultExpandedSection?: ConnectedIOSApp;
}> = ({ devices, defaultExpandedSection }) => {
  const normalizedDevices = devices.map(({ device, settings }) => ({
    device,
    settings: settingsForDevice(device, settings),
  }));
  const musicConnections: MusicDeviceConnection[] = normalizedDevices.flatMap(
    ({ device, settings }) => (settings.music ? [{ device, music: settings.music }] : []),
  );

  return (
    <InPageContext>
      <IosPersonSettingsPage
        personName="Jude"
        musicState={{ status: `success`, data: musicConnections }}
        defaultExpandedMusic={defaultExpandedSection === `music`}
      >
        {normalizedDevices.map(({ device, settings }) => (
          <IosDeviceSettingsSection key={device.id} device={device}>
            <DeviceSettings
              settings={settings}
              defaultExpandedSection={defaultExpandedSection}
            />
          </IosDeviceSettingsSection>
        ))}
      </IosPersonSettingsPage>
    </InPageContext>
  );
};

const expandSections = (canvasElement: HTMLElement, titles: string[]): void => {
  const buttons = Array.from(canvasElement.querySelectorAll<HTMLButtonElement>(`button`));
  for (const title of titles) {
    const button = buttons.find(
      (element) => element.getAttribute(`aria-label`) === title,
    );
    if (!button) {
      throw new globalThis.Error(`${title} section not found`);
    }
    button.click();
  }
};

const waitForRender = (): Promise<void> =>
  new Promise((resolveRender) =>
    requestAnimationFrame(() => requestAnimationFrame(() => resolveRender())),
  );

export const IosMultipleDevices = {
  name: 'iPhone and iPad (shared and device settings)',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <IosOverview
      devices={[
        { device: iphoneDevice, settings: iosDeviceSettingsAllAppsConnected },
        {
          device: ipadDevice,
          settings: {
            ...iosDeviceSettingsNoBlocker,
            podcasts: iosDeviceSettingsWithPodcasts.podcasts,
            music: iosDeviceSettingsAllAppsConnected.music,
          },
        },
      ]}
    />
  ),
};

export const IosMusicMixedDeviceStates = {
  name: 'iPhone and iPad (Music mixed device states)',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <IosOverview
      defaultExpandedSection="music"
      devices={[
        { device: iphoneDevice, settings: iosDeviceSettingsMusicTrial },
        { device: ipadDevice, settings: iosDeviceSettingsMusicUnavailable },
      ]}
    />
  ),
};

export const IosMusicOneOfTwoDevices = {
  name: 'iPhone and iPad (Music on one device)',
  parameters: { ...galleryParameters, screenshotsAt: ['desktop'] },
  render: () => (
    <IosOverview
      defaultExpandedSection="music"
      devices={[
        { device: iphoneDevice, settings: iosDeviceSettingsAllAppsConnected },
        { device: ipadDevice, settings: iosDeviceSettingsNoBlocker },
      ]}
    />
  ),
};

export const IosMusicNotConnected = {
  name: 'iPhone and iPad (Music not connected)',
  parameters: { ...galleryParameters, screenshotsAt: ['desktop'] },
  render: () => (
    <IosOverview
      defaultExpandedSection="music"
      devices={[
        { device: iphoneDevice, settings: iosDeviceSettingsWithPodcasts },
        { device: ipadDevice, settings: iosDeviceSettingsNoBlocker },
      ]}
    />
  ),
};

export const IosAllAppsConnected = {
  name: 'iPhone and iPad (all apps connected)',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <IosOverview
      devices={[{ device: iphoneDevice, settings: iosDeviceSettingsAllAppsConnected }]}
    />
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) => {
    expandSections(canvasElement, [
      `Gertrude Music`,
      `Gertrude Blocker`,
      `Gertrude Podcasts`,
    ]);
  },
};

export const IosLinkedMusicSection = {
  name: 'iPhone and iPad (linked Music section)',
  render: () => (
    <IosOverview
      defaultExpandedSection="music"
      devices={[{ device: iphoneDevice, settings: iosDeviceSettingsAllAppsConnected }]}
    />
  ),
};

export const IosUnsupervised = {
  name: 'iPhone and iPad (unsupervised)',
  parameters: { ...galleryParameters, screenshotsAt: ['desktop'] },
  render: () => (
    <IosOverview
      devices={[{ device: iphoneDevice, settings: iosDeviceSettingsUnsupervised }]}
    />
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) => {
    expandSections(canvasElement, [`Gertrude Blocker`]);
  },
};

export const IosAppsNotConnected = {
  name: 'iPhone and iPad (apps not connected)',
  parameters: { ...galleryParameters, screenshotsAt: ['desktop'] },
  render: () => (
    <IosOverview
      devices={[{ device: iphoneDevice, settings: iosDeviceSettingsNoBlocker }]}
    />
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) => {
    expandSections(canvasElement, [
      `Gertrude Music`,
      `Gertrude Blocker`,
      `Gertrude Podcasts`,
    ]);
  },
};

export const IosPodcastsTrial = {
  name: 'iPhone and iPad (podcasts trial)',
  parameters: { ...galleryParameters, screenshotsAt: ['desktop'] },
  render: () => (
    <IosOverview
      devices={[{ device: iphoneDevice, settings: iosDeviceSettingsPodcastsTrial }]}
    />
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) => {
    expandSections(canvasElement, [`Gertrude Podcasts`]);
  },
};

export const IosPodcastsExpiring = {
  name: 'iPhone and iPad (podcasts expiring)',
  parameters: { ...galleryParameters, screenshotsAt: ['desktop'] },
  render: () => (
    <IosOverview
      devices={[{ device: iphoneDevice, settings: iosDeviceSettingsPodcastsExpiring }]}
    />
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) => {
    expandSections(canvasElement, [`Gertrude Podcasts`]);
  },
};

export const IosPodcastsPaused = {
  name: 'iPhone and iPad (podcasts paused)',
  parameters: { ...galleryParameters, screenshotsAt: ['desktop'] },
  render: () => (
    <IosOverview
      devices={[{ device: iphoneDevice, settings: iosDeviceSettingsPodcastsPaused }]}
    />
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) => {
    expandSections(canvasElement, [`Gertrude Podcasts`]);
  },
};

export const IosPodcastsPinReset = {
  name: 'iPhone and iPad (podcasts PIN reset)',
  parameters: { ...galleryParameters, screenshotsAt: ['desktop'] },
  render: () => (
    <IosOverview
      devices={[{ device: iphoneDevice, settings: iosDeviceSettingsWithPodcasts }]}
    />
  ),
  play: async ({ canvasElement }: { canvasElement: HTMLElement }) => {
    expandSections(canvasElement, [`Gertrude Podcasts`]);
    await waitForRender();
    const resetButton = Array.from(
      canvasElement.querySelectorAll<HTMLButtonElement>(`button`),
    ).find((button) => button.textContent?.trim() === `Reset PIN`);
    if (!resetButton) {
      throw new globalThis.Error(`Reset PIN button not found`);
    }
    resetButton.click();
    await waitForRender();
  },
};

export const IosMusicUnavailable = {
  name: 'iPhone and iPad (music unavailable)',
  parameters: { ...galleryParameters, screenshotsAt: ['desktop'] },
  render: () => (
    <IosOverview
      defaultExpandedSection="music"
      devices={[{ device: iphoneDevice, settings: iosDeviceSettingsMusicUnavailable }]}
    />
  ),
};

export const IosMusicTrial = {
  name: 'iPhone and iPad (Music free trial)',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <IosOverview
      defaultExpandedSection="music"
      devices={[{ device: iphoneDevice, settings: iosDeviceSettingsMusicTrial }]}
    />
  ),
};

export const IosLoading = {
  name: 'iPhone and iPad (loading)',
  parameters: { ...galleryParameters, screenshotsAt: ['desktop'] },
  render: () => (
    <InPageContext>
      <IosPersonSettingsPage personName="Jude" musicState={{ status: `loading` }}>
        <IosDeviceSettingsSection device={iphoneDevice}>
          <IosSettingsPage
            state={{ status: `loading` }}
            onSaveBlockedGroups={() => {}}
            onSaveProfile={() => {}}
          />
        </IosDeviceSettingsSection>
      </IosPersonSettingsPage>
    </InPageContext>
  ),
};

export const IosError = {
  name: 'iPhone and iPad (error)',
  parameters: { ...galleryParameters, screenshotsAt: ['desktop'] },
  render: () => (
    <InPageContext>
      <IosPersonSettingsPage
        personName="Jude"
        musicState={{
          status: `error`,
          message: `Check your connection and try again.`,
          onRetry: () => {},
        }}
      >
        <IosDeviceSettingsSection device={iphoneDevice}>
          <IosSettingsPage
            state={{
              status: `error`,
              message: `Check your connection and try again.`,
              onRetry: () => {},
            }}
            onSaveBlockedGroups={() => {}}
            onSaveProfile={() => {}}
          />
        </IosDeviceSettingsSection>
      </IosPersonSettingsPage>
    </InPageContext>
  ),
};
