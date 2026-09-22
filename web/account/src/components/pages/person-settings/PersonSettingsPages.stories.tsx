import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import React from 'react';
import type { IOSDevice } from '#/components/types';
import type {
  IosDeviceSettingsConfiguration,
  MusicDeviceConnection,
} from './IosSettingsPage.types';
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

interface DeviceStorySettings {
  device: IOSDevice;
  settings: IosDeviceSettingsConfiguration;
}

const alternateIphone: IOSDevice = {
  ...iphoneDevice,
  id: `iphone-2`,
  modelName: `iPhone 15`,
  modelIdentifier: `iPhone15,4`,
};

const alternateIpad: IOSDevice = {
  ...ipadDevice,
  id: `ipad-2`,
  modelName: `iPad`,
  modelIdentifier: `iPad13,18`,
};

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
}> = ({ settings }) => (
  <IosSettingsPage
    state={{ status: `success`, data: settings }}
    onSaveBlockedGroups={() => {}}
    onSaveProfile={() => {}}
    onRequestPodcastsPinReset={() => Promise.resolve(481_920)}
  />
);

const IosOverview: React.FC<{
  devices: DeviceStorySettings[];
}> = ({ devices }) => {
  const normalizedDevices = devices.map(({ device, settings }) => ({
    device,
    settings: settingsForDevice(device, settings),
  }));
  const musicConnections: MusicDeviceConnection[] = normalizedDevices.flatMap(
    ({ device, settings }) => (settings.music ? [{ device, music: settings.music }] : []),
  );

  return (
    <InPageContext>
      <IosPersonSettingsPage personName="Jude" musicConnections={musicConnections}>
        {normalizedDevices.map(({ device, settings }) => (
          <IosDeviceSettingsSection key={device.id} device={device}>
            <DeviceSettings settings={settings} />
          </IosDeviceSettingsSection>
        ))}
      </IosPersonSettingsPage>
    </InPageContext>
  );
};

const expandSections = (scope: ParentNode, titles: string[]): void => {
  const buttons = Array.from(scope.querySelectorAll<HTMLButtonElement>(`button`));
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

const expandDeviceSections = (
  canvasElement: HTMLElement,
  deviceId: string,
  titles: string[],
): void => {
  const deviceSection = canvasElement.querySelector<HTMLElement>(`[id="${deviceId}"]`);
  if (!deviceSection) {
    throw new globalThis.Error(`${deviceId} device section not found`);
  }
  expandSections(deviceSection, titles);
};

const waitForRender = (): Promise<void> =>
  new Promise((resolveRender) =>
    requestAnimationFrame(() => requestAnimationFrame(() => resolveRender())),
  );

export const IosOverviewStory = {
  name: 'iPhone and iPad (overview)',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <IosOverview
      devices={[
        { device: iphoneDevice, settings: iosDeviceSettingsAllAppsConnected },
        { device: ipadDevice, settings: iosDeviceSettingsNoBlocker },
      ]}
    />
  ),
};

export const IosExpandedSettings = {
  name: 'iPhone and iPad (expanded settings)',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <IosOverview
      devices={[
        { device: iphoneDevice, settings: iosDeviceSettingsAllAppsConnected },
        {
          device: ipadDevice,
          settings: {
            ...iosDeviceSettingsNoBlocker,
            music: iosDeviceSettingsMusicTrial.music,
          },
        },
      ]}
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

export const IosAlternateStates = {
  name: 'iPhone and iPad (alternate states)',
  parameters: { ...galleryParameters, screenshotsAt: ['desktop'] },
  render: () => (
    <IosOverview
      devices={[
        {
          device: iphoneDevice,
          settings: {
            ...iosDeviceSettingsNoBlocker,
            music: iosDeviceSettingsMusicUnavailable.music,
          },
        },
        {
          device: ipadDevice,
          settings: {
            ...iosDeviceSettingsUnsupervised,
            podcasts: iosDeviceSettingsPodcastsTrial.podcasts,
          },
        },
        { device: alternateIphone, settings: iosDeviceSettingsPodcastsExpiring },
        {
          device: alternateIpad,
          settings: {
            ...iosDeviceSettingsNoBlocker,
            podcasts: iosDeviceSettingsPodcastsPaused.podcasts,
          },
        },
      ]}
    />
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) => {
    expandSections(canvasElement, [`Gertrude Music`]);
    expandDeviceSections(canvasElement, iphoneDevice.id, [
      `Gertrude Blocker`,
      `Gertrude Podcasts`,
    ]);
    expandDeviceSections(canvasElement, ipadDevice.id, [
      `Gertrude Blocker`,
      `Gertrude Podcasts`,
    ]);
    expandDeviceSections(canvasElement, alternateIphone.id, [`Gertrude Podcasts`]);
    expandDeviceSections(canvasElement, alternateIpad.id, [`Gertrude Podcasts`]);
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

export const IosLoadingAndError = {
  name: 'iPhone and iPad (loading and error)',
  parameters: { ...galleryParameters, screenshotsAt: ['desktop'] },
  render: () => (
    <InPageContext>
      <IosPersonSettingsPage personName="Jude" musicConnections={[]}>
        <IosDeviceSettingsSection device={iphoneDevice}>
          <IosSettingsPage
            state={{ status: `loading` }}
            onSaveBlockedGroups={() => {}}
            onSaveProfile={() => {}}
          />
        </IosDeviceSettingsSection>
        <IosDeviceSettingsSection device={ipadDevice}>
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
