import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import React from 'react';
import type { IosDeviceSettingsConfiguration } from './IosSettingsPage.types';
import PersonSettingsShellPage from '../people/PersonSettingsShellPage';
import IosSettingsPage from './IosSettingsPage';
import {
  iosDeviceSettingsAllAppsConnected,
  iosDeviceSettingsMusicUnavailable,
  iosDeviceSettingsNoBlocker,
  iosDeviceSettingsPodcastsExpiring,
  iosDeviceSettingsPodcastsPaused,
  iosDeviceSettingsPodcastsTrial,
  iosDeviceSettingsUnsupervised,
  iosDeviceSettingsWithPodcasts,
} from '#/components/storybook/fixtures';

const meta = {
  title: 'Account/Pages/People/Person Settings',
  parameters: { layout: 'fullscreen' },
};

export default meta;

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

const IosSettings: React.FC<{ settings: IosDeviceSettingsConfiguration }> = ({
  settings,
}) => (
  <IosSettingsPage
    state={{ status: `success`, data: settings }}
    onSaveBlockedGroups={() => {}}
    onSaveProfile={() => {}}
    onRequestPodcastsPinReset={() => Promise.resolve(481_920)}
  />
);

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

export const IosAllAppsConnected = {
  name: 'iPhone and iPad (all apps connected)',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <InPageContext>
      <IosSettings settings={iosDeviceSettingsAllAppsConnected} />
    </InPageContext>
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) => {
    expandSections(canvasElement, [
      `Gertrude Blocker`,
      `Gertrude Music`,
      `Gertrude Podcasts`,
    ]);
  },
};

export const IosUnsupervised = {
  name: 'iPhone and iPad (unsupervised)',
  parameters: { ...galleryParameters, screenshotsAt: ['desktop'] },
  render: () => (
    <InPageContext>
      <IosSettings settings={iosDeviceSettingsUnsupervised} />
    </InPageContext>
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) => {
    expandSections(canvasElement, [`Gertrude Blocker`]);
  },
};

export const IosAppsNotConnected = {
  name: 'iPhone and iPad (apps not connected)',
  parameters: { ...galleryParameters, screenshotsAt: ['desktop'] },
  render: () => (
    <InPageContext>
      <IosSettings settings={iosDeviceSettingsNoBlocker} />
    </InPageContext>
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) => {
    expandSections(canvasElement, [
      `Gertrude Blocker`,
      `Gertrude Music`,
      `Gertrude Podcasts`,
    ]);
  },
};

export const IosPodcastsTrial = {
  name: 'iPhone and iPad (podcasts trial)',
  parameters: { ...galleryParameters, screenshotsAt: ['desktop'] },
  render: () => (
    <InPageContext>
      <IosSettings settings={iosDeviceSettingsPodcastsTrial} />
    </InPageContext>
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) => {
    expandSections(canvasElement, [`Gertrude Podcasts`]);
  },
};

export const IosPodcastsExpiring = {
  name: 'iPhone and iPad (podcasts expiring)',
  parameters: { ...galleryParameters, screenshotsAt: ['desktop'] },
  render: () => (
    <InPageContext>
      <IosSettings settings={iosDeviceSettingsPodcastsExpiring} />
    </InPageContext>
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) => {
    expandSections(canvasElement, [`Gertrude Podcasts`]);
  },
};

export const IosPodcastsPaused = {
  name: 'iPhone and iPad (podcasts paused)',
  parameters: { ...galleryParameters, screenshotsAt: ['desktop'] },
  render: () => (
    <InPageContext>
      <IosSettings settings={iosDeviceSettingsPodcastsPaused} />
    </InPageContext>
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) => {
    expandSections(canvasElement, [`Gertrude Podcasts`]);
  },
};

export const IosPodcastsPinReset = {
  name: 'iPhone and iPad (podcasts PIN reset)',
  parameters: { ...galleryParameters, screenshotsAt: ['desktop'] },
  render: () => (
    <InPageContext>
      <IosSettings settings={iosDeviceSettingsWithPodcasts} />
    </InPageContext>
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
    <InPageContext>
      <IosSettings settings={iosDeviceSettingsMusicUnavailable} />
    </InPageContext>
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) => {
    expandSections(canvasElement, [`Gertrude Music`]);
  },
};

export const IosLoading = {
  name: 'iPhone and iPad (loading)',
  parameters: { ...galleryParameters, screenshotsAt: ['desktop'] },
  render: () => (
    <InPageContext>
      <IosSettingsPage
        state={{ status: `loading` }}
        onSaveBlockedGroups={() => {}}
        onSaveProfile={() => {}}
      />
    </InPageContext>
  ),
};

export const IosError = {
  name: 'iPhone and iPad (error)',
  parameters: { ...galleryParameters, screenshotsAt: ['desktop'] },
  render: () => (
    <InPageContext>
      <IosSettingsPage
        state={{
          status: `error`,
          message: `Check your connection and try again.`,
          onRetry: () => {},
        }}
        onSaveBlockedGroups={() => {}}
        onSaveProfile={() => {}}
      />
    </InPageContext>
  ),
};
