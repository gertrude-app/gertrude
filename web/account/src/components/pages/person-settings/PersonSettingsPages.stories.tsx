import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import React from 'react';
import type { MusicCurationState } from '#/components/person-settings/useMusicCuration';
import type { IOSDevice } from '#/components/types';
import type {
  IosDeviceSettingsConfiguration,
  MusicDeviceConnection,
} from './IosSettingsPage.types';
import type {
  GetMusicAlbumCuration,
  GetMusicCuration,
  SearchMusicCatalog_v2,
} from '@shared/pairql/src/account';
import PersonSettingsShellPage from '../people/PersonSettingsShellPage';
import IosDeviceSettingsSection from './IosDeviceSettingsSection';
import IosPersonSettingsPage from './IosPersonSettingsPage';
import IosSettingsPage from './IosSettingsPage';
import MusicCuration from '#/components/person-settings/MusicCuration';
import {
  iosDeviceSettingsAllAppsConnected,
  iosDeviceSettingsMusicConnected,
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

const musicCuration: GetMusicCuration.Output = {
  revision: 4,
  artists: [
    {
      id: `artist-1`,
      name: `The Weepies`,
      createdAt: `2026-08-04T12:00:00Z`,
      catalogMetadata: { genreNames: [`Folk`] },
    },
    {
      id: `artist-3`,
      name: `Iron & Wine`,
      createdAt: `2026-08-17T12:00:00Z`,
      catalogMetadata: {
        artwork: { url: `/example-artist-art/iron-and-wine.jpg` },
        genreNames: [`Singer/Songwriter`, `Folk`],
      },
    },
  ],
  albums: [
    {
      id: `album-1`,
      title: `Echoes and Pines`,
      artistName: `The Northline`,
      artworkUrl: `/example-album-art/echoes-and-pines.webp`,
      catalogTrackCount: 3,
      selectedTrackCount: 1,
      scope: `selectedTracks`,
      showsArtwork: true,
      createdAt: `2026-08-01T12:00:00Z`,
    },
    {
      id: `album-2`,
      title: `Midnight Signals`,
      artistName: `The Outliers`,
      artworkUrl: `/example-album-art/midnight-signals.webp`,
      catalogTrackCount: 3,
      selectedTrackCount: 3,
      scope: `wholeAlbum`,
      showsArtwork: true,
      createdAt: `2026-07-01T12:00:00Z`,
    },
    {
      id: `album-4`,
      title: `Tide Bloom`,
      artistName: `Mira Sol`,
      artworkUrl: `/example-album-art/tide-bloom.webp`,
      catalogTrackCount: 3,
      selectedTrackCount: 2,
      scope: `selectedTracks`,
      showsArtwork: true,
      createdAt: `2026-08-12T12:00:00Z`,
    },
    {
      id: `album-5`,
      title: `Glass Harbor`,
      artistName: `The Harbor Lights`,
      catalogTrackCount: 3,
      selectedTrackCount: 3,
      scope: `wholeAlbum`,
      showsArtwork: false,
      createdAt: `2026-07-23T12:00:00Z`,
    },
  ],
};

const emptyMusicCuration: GetMusicCuration.Output = {
  revision: 0,
  artists: [],
  albums: [],
};

const albumCuration: GetMusicAlbumCuration.Output = {
  revision: 4,
  id: `album-1`,
  title: `Echoes and Pines`,
  artistName: `The Northline`,
  scope: `selectedTracks`,
  catalogTrackCount: 3,
  selectedTrackCount: 1,
  canEdit: true,
  tracks: [
    {
      id: `track-1`,
      title: `The Long Way Home`,
      artistName: `The Northline`,
      durationInMillis: 241_000,
      trackNumber: 1,
      discNumber: 1,
      isSelected: true,
    },
    {
      id: `track-2`,
      title: `Morning Light`,
      artistName: `The Northline`,
      durationInMillis: 192_000,
      trackNumber: 2,
      discNumber: 1,
      isSelected: false,
    },
    {
      id: `track-3`,
      title: `Another Place`,
      artistName: `The Northline`,
      contentRating: `explicit`,
      durationInMillis: 220_000,
      trackNumber: 3,
      discNumber: 1,
      isSelected: false,
    },
  ],
};

const musicSearchResults: SearchMusicCatalog_v2.Output = {
  revision: 4,
  items: [
    {
      kind: `track`,
      track: {
        id: `track-2`,
        title: `Morning Light`,
        artistName: `The Northline`,
        albumTitle: `Echoes and Pines`,
        preferredAlbumId: `album-1`,
        artworkUrl: `/example-album-art/echoes-and-pines.webp`,
        status: { kind: `available` },
      },
    },
    {
      kind: `album`,
      album: {
        id: `album-3`,
        title: `Orange Light`,
        artistName: `The Northline`,
        artworkUrl: `/example-album-art/orange-light.webp`,
        trackCount: 3,
        status: { kind: `available`, selectedTrackCount: 0 },
      },
    },
    {
      kind: `artist`,
      artist: {
        id: `artist-2`,
        name: `The Paper Kites`,
        status: `available`,
        catalogMetadata: { genreNames: [`Alternative`, `Folk`] },
      },
    },
  ],
};

const newAlbumCuration: GetMusicAlbumCuration.Output = {
  ...albumCuration,
  id: `album-3`,
  title: `Orange Light`,
  scope: `none`,
  selectedTrackCount: 0,
  tracks: albumCuration.tracks.map((track, index) => ({
    ...track,
    id: `orange-track-${index + 1}`,
    title: [`First Light`, `Open Road`, `Daybreak`][index]!,
    isSelected: false,
  })),
};

const tideBloomCuration: GetMusicAlbumCuration.Output = {
  ...albumCuration,
  id: `album-4`,
  title: `Tide Bloom`,
  artistName: `Mira Sol`,
  selectedTrackCount: 2,
  tracks: albumCuration.tracks.map((track, index) => ({
    ...track,
    id: `tide-track-${index + 1}`,
    title: [`Wildflower`, `Blue Current`, `Summer Rain`][index]!,
    artistName: `Mira Sol`,
    isSelected: index !== 1,
  })),
};

const noop = (): void => {};

const defaultMusicState: MusicCurationState = {
  query: ``,
  setQuery: noop,
  searchOpen: false,
  setSearchOpen: noop,
  expandedAlbum: undefined,
  albumMessage: undefined,
  artistConfirmation: undefined,
  setArtistConfirmation: noop,
  artistToRemove: undefined,
  setArtistToRemove: noop,
  albumToRemove: undefined,
  setAlbumToRemove: noop,
  curation: {
    data: musicCuration,
    isPending: false,
    isError: false,
    isSuccess: true,
    error: null,
    refetch: noop,
  },
  albumQuery: { isPending: false, isError: false, error: null, refetch: noop },
  search: {
    data: undefined,
    isPending: false,
    isError: false,
    isSuccess: false,
    status: `idle`,
    error: null,
    variables: undefined,
    mutate: noop,
    reset: noop,
  },
  trackApproval: { isPending: false, variables: undefined, mutate: noop },
  albumApproval: { isPending: false, variables: undefined, mutate: noop },
  artistApproval: { isPending: false, variables: undefined, mutate: noop },
  removeArtist: { isPending: false, mutate: noop },
  saveAlbum: { isPending: false, mutate: noop },
  removeAlbum: { isPending: false, mutate: noop },
  closeAlbum: () => true,
  toggleAlbum: noop,
  closeSearch: noop,
  leaveSearchEditor: () => true,
  album: undefined,
  onAlbumDirtyChange: noop,
};

const searchMusicState: MusicCurationState = {
  ...defaultMusicState,
  query: `The Northline`,
  searchOpen: true,
  search: {
    ...defaultMusicState.search,
    data: musicSearchResults,
    isSuccess: true,
    status: `success`,
    variables: { childId: `person-1`, query: `The Northline`, limit: 10 },
  },
};

const albumMusicState: MusicCurationState = {
  ...defaultMusicState,
  expandedAlbum: { id: `album-4`, surface: `library`, rowId: `album-4`, session: 1 },
  album: tideBloomCuration,
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
  musicState?: MusicCurationState;
  defaultExpandedMusic?: boolean;
}> = ({ devices, musicState = defaultMusicState, defaultExpandedMusic }) => {
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
        musicConnections={musicConnections}
        defaultExpandedMusic={defaultExpandedMusic}
        musicCuration={
          <MusicCuration personId="person-1" personName="Jude" state={musicState} />
        }
      >
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

const musicDevices: DeviceStorySettings[] = [
  { device: iphoneDevice, settings: iosDeviceSettingsMusicConnected },
  { device: ipadDevice, settings: iosDeviceSettingsMusicTrial },
];

export const IosMusicLibrary = {
  name: 'iPhone and iPad (allowed music)',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => <IosOverview devices={musicDevices} defaultExpandedMusic />,
};

export const IosMusicLibraryLoading = {
  name: 'iPhone and iPad (loading allowed music)',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <IosOverview
      devices={musicDevices}
      defaultExpandedMusic
      musicState={{
        ...defaultMusicState,
        curation: {
          ...defaultMusicState.curation,
          data: undefined,
          isPending: true,
          isSuccess: false,
        },
      }}
    />
  ),
};

export const IosMusicRemoveAlbum = {
  name: 'iPhone and iPad (remove album)',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <IosOverview
      devices={musicDevices}
      defaultExpandedMusic
      musicState={{
        ...defaultMusicState,
        albumToRemove: {
          album: musicCuration.albums[2]!,
          revision: musicCuration.revision,
        },
      }}
    />
  ),
};

export const IosMusicEmpty = {
  name: 'iPhone and iPad (no music yet)',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <IosOverview
      devices={musicDevices}
      defaultExpandedMusic
      musicState={{
        ...defaultMusicState,
        curation: { ...defaultMusicState.curation, data: emptyMusicCuration },
      }}
    />
  ),
};

export const IosMusicSearch = {
  name: 'iPhone and iPad (searching music)',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <IosOverview
      devices={musicDevices}
      defaultExpandedMusic
      musicState={searchMusicState}
    />
  ),
};

export const IosMusicSearchLoading = {
  name: 'iPhone and iPad (search in progress)',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <IosOverview
      devices={musicDevices}
      defaultExpandedMusic
      musicState={{
        ...searchMusicState,
        search: {
          ...searchMusicState.search,
          data: undefined,
          isPending: true,
          isSuccess: false,
          status: `pending`,
        },
      }}
    />
  ),
};

export const IosMusicSearchTracks = {
  name: 'iPhone and iPad (choose tracks from search)',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <IosOverview
      devices={musicDevices}
      defaultExpandedMusic
      musicState={{
        ...searchMusicState,
        expandedAlbum: {
          id: `album-3`,
          surface: `search`,
          rowId: `album-album-3`,
          session: 1,
        },
        album: newAlbumCuration,
      }}
    />
  ),
};

export const IosMusicAlbumTracks = {
  name: 'iPhone and iPad (album tracks)',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <IosOverview
      devices={musicDevices}
      defaultExpandedMusic
      musicState={albumMusicState}
    />
  ),
};

export const IosMusicAlbumLoading = {
  name: 'iPhone and iPad (loading album tracks)',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <IosOverview
      devices={musicDevices}
      defaultExpandedMusic
      musicState={{
        ...albumMusicState,
        album: undefined,
        albumQuery: { ...albumMusicState.albumQuery, isPending: true },
      }}
    />
  ),
};

export const IosMusicAlbumSaving = {
  name: 'iPhone and iPad (saving album tracks)',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <IosOverview
      devices={musicDevices}
      defaultExpandedMusic
      musicState={{
        ...albumMusicState,
        initialAlbumSelectedTrackIds: tideBloomCuration.tracks.map(({ id }) => id),
        saveAlbum: { ...albumMusicState.saveAlbum, isPending: true },
      }}
    />
  ),
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
      <IosPersonSettingsPage personName="Jude" musicConnections={[]} musicCuration={null}>
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
