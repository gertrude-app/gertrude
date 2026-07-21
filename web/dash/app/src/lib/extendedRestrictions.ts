import type { ExtendedSupervisionControls } from '@dash/types';

export type ExtControlsState = {
  allowItunes: boolean | null;
  allowMusicService: boolean | null;
  allowRadioService: boolean | null;
  allowNews: boolean | null;
  allowBookstore: boolean | null;
  allowExplicitContent: boolean | null;
  ratingMovies: number | null;
  ratingTvShows: number | null;
  allowSafari: boolean | null;
  allowSpotlightInternetResults: boolean | null;
  allowDefinitionLookup: boolean | null;
  allowAutomaticAppDownloads: boolean | null;
  allowAppClips: boolean | null;
  allowSystemAppRemoval: boolean | null;
  allowAssistant: boolean | null;
  allowGameCenter: boolean | null;
  forceDelayedSoftwareUpdates: boolean | null;
  enforcedSoftwareUpdateDelay: number | null;
  forceAutomaticDateAndTime: boolean | null;
};

export type ExtField = keyof ExtControlsState;

export const EXTENDED_RESTRICTION_FIELDS: ExtField[] = [
  `allowItunes`,
  `allowMusicService`,
  `allowRadioService`,
  `allowNews`,
  `allowBookstore`,
  `allowExplicitContent`,
  `ratingMovies`,
  `ratingTvShows`,
  `allowSafari`,
  `allowSpotlightInternetResults`,
  `allowDefinitionLookup`,
  `allowAutomaticAppDownloads`,
  `allowAppClips`,
  `allowSystemAppRemoval`,
  `allowAssistant`,
  `allowGameCenter`,
  `forceDelayedSoftwareUpdates`,
  `enforcedSoftwareUpdateDelay`,
  `forceAutomaticDateAndTime`,
];

export const EMPTY_EXTENDED: ExtControlsState = {
  allowItunes: null,
  allowMusicService: null,
  allowRadioService: null,
  allowNews: null,
  allowBookstore: null,
  allowExplicitContent: null,
  ratingMovies: null,
  ratingTvShows: null,
  allowSafari: null,
  allowSpotlightInternetResults: null,
  allowDefinitionLookup: null,
  allowAutomaticAppDownloads: null,
  allowAppClips: null,
  allowSystemAppRemoval: null,
  allowAssistant: null,
  allowGameCenter: null,
  forceDelayedSoftwareUpdates: null,
  enforcedSoftwareUpdateDelay: null,
  forceAutomaticDateAndTime: null,
};

export const SOFTWARE_UPDATE_DELAY_DEFAULT = 30;
export const SOFTWARE_UPDATE_DELAY_MIN = 1;
export const SOFTWARE_UPDATE_DELAY_MAX = 90;

export type RestrictionControl = {
  field: ExtField;
  label: string;
  restrictValue: boolean | number;
  delayDays?: boolean;
  hint?: string;
  onWord?: string;
  offWord?: string;
};

export type RestrictionGroup = {
  id: string;
  title: string;
  description: string;
  controls: RestrictionControl[];
};

export const EXTENDED_RESTRICTION_GROUPS: RestrictionGroup[] = [
  {
    id: `web`,
    title: `Block web browsing & search`,
    description: `Remove the Safari browser and keep web content out of search.`,
    controls: [
      { field: `allowSafari`, label: `Block the Safari browser`, restrictValue: false },
      {
        field: `allowSpotlightInternetResults`,
        label: `Block web results in search`,
        restrictValue: false,
        hint: `Web suggestions that show up when searching from the home screen`,
      },
      {
        field: `allowDefinitionLookup`,
        label: `Block definition look-up`,
        restrictValue: false,
        hint: `The "Look Up" option for defining or searching selected text`,
      },
    ],
  },
  {
    id: `media`,
    title: `Block Apple media & stores`,
    description: `Hide Apple's built-in media and store apps like iTunes, Music, and News.`,
    controls: [
      { field: `allowItunes`, label: `Block the iTunes Store`, restrictValue: false },
      { field: `allowMusicService`, label: `Block Apple Music`, restrictValue: false },
      {
        field: `allowRadioService`,
        label: `Block Apple Music radio`,
        restrictValue: false,
      },
      { field: `allowNews`, label: `Block Apple News`, restrictValue: false },
      {
        field: `allowBookstore`,
        label: `Block the Apple Books store`,
        restrictValue: false,
      },
    ],
  },
  {
    id: `mature`,
    title: `Block explicit & mature content`,
    description: `Block explicit media and limit movies and TV to all-ages ratings.`,
    controls: [
      {
        field: `allowExplicitContent`,
        label: `Block explicit music, podcasts & books`,
        restrictValue: false,
      },
      { field: `ratingMovies`, label: `Block mature-rated movies`, restrictValue: 0 },
      { field: `ratingTvShows`, label: `Block mature-rated TV shows`, restrictValue: 0 },
    ],
  },
  {
    id: `apps`,
    title: `Restrict apps`,
    description: `Block automatic downloads, App Clips, and deleting built-in apps.`,
    controls: [
      {
        field: `allowAutomaticAppDownloads`,
        label: `Block automatic app downloads`,
        restrictValue: false,
        hint: `Apps bought on another device won't auto-install here`,
      },
      {
        field: `allowAppClips`,
        label: `Block App Clips`,
        restrictValue: false,
        hint: `Mini versions of apps that open instantly without installing`,
      },
      {
        field: `allowSystemAppRemoval`,
        label: `Block deleting built-in apps`,
        restrictValue: false,
        hint: `Keeps Apple's built-in apps (like Safari and Mail) from being deleted`,
      },
    ],
  },
  {
    id: `assistant`,
    title: `Block Siri & Game Center`,
    description: `Turn off the Siri assistant and Apple's Game Center.`,
    controls: [
      { field: `allowAssistant`, label: `Block Siri`, restrictValue: false },
      { field: `allowGameCenter`, label: `Block Game Center`, restrictValue: false },
    ],
  },
  {
    id: `updates`,
    title: `Delay updates & lock the clock`,
    description: `Hold back software updates and stop the device clock from being changed.`,
    controls: [
      {
        field: `forceDelayedSoftwareUpdates`,
        label: `Delay software updates`,
        restrictValue: true,
        delayDays: true,
        onWord: `Delayed`,
        offWord: `Off`,
      },
      {
        field: `forceAutomaticDateAndTime`,
        label: `Prevent changing the date & time`,
        restrictValue: true,
        hint: `Stops the clock from being changed to get around Screen Time limits`,
        onWord: `Locked`,
        offWord: `Off`,
      },
    ],
  },
];

export function isControlOn(ext: ExtControlsState, control: RestrictionControl): boolean {
  return ext[control.field] !== null;
}

export function controlOnValues(control: RestrictionControl): Partial<ExtControlsState> {
  const values: Partial<ExtControlsState> = {};
  (values as Record<ExtField, boolean | number | null>)[control.field] =
    control.restrictValue;
  if (control.delayDays) {
    values.enforcedSoftwareUpdateDelay = SOFTWARE_UPDATE_DELAY_DEFAULT;
  }
  return values;
}

export function controlOffValues(control: RestrictionControl): Partial<ExtControlsState> {
  const values: Partial<ExtControlsState> = {};
  (values as Record<ExtField, boolean | number | null>)[control.field] = null;
  if (control.delayDays) {
    values.enforcedSoftwareUpdateDelay = null;
  }
  return values;
}

export function groupValues(
  group: RestrictionGroup,
  on: boolean,
): Partial<ExtControlsState> {
  return group.controls.reduce<Partial<ExtControlsState>>(
    (acc, control) => ({
      ...acc,
      ...(on ? controlOnValues(control) : controlOffValues(control)),
    }),
    {},
  );
}

export function normalizeExtended(
  ext: ExtendedSupervisionControls | undefined,
): ExtControlsState {
  return {
    allowItunes: ext?.allowItunes ?? null,
    allowMusicService: ext?.allowMusicService ?? null,
    allowRadioService: ext?.allowRadioService ?? null,
    allowNews: ext?.allowNews ?? null,
    allowBookstore: ext?.allowBookstore ?? null,
    allowExplicitContent: ext?.allowExplicitContent ?? null,
    ratingMovies: ext?.ratingMovies ?? null,
    ratingTvShows: ext?.ratingTvShows ?? null,
    allowSafari: ext?.allowSafari ?? null,
    allowSpotlightInternetResults: ext?.allowSpotlightInternetResults ?? null,
    allowDefinitionLookup: ext?.allowDefinitionLookup ?? null,
    allowAutomaticAppDownloads: ext?.allowAutomaticAppDownloads ?? null,
    allowAppClips: ext?.allowAppClips ?? null,
    allowSystemAppRemoval: ext?.allowSystemAppRemoval ?? null,
    allowAssistant: ext?.allowAssistant ?? null,
    allowGameCenter: ext?.allowGameCenter ?? null,
    forceDelayedSoftwareUpdates: ext?.forceDelayedSoftwareUpdates ?? null,
    enforcedSoftwareUpdateDelay: ext?.enforcedSoftwareUpdateDelay ?? null,
    forceAutomaticDateAndTime: ext?.forceAutomaticDateAndTime ?? null,
  };
}

export function extendedControlsPayload(
  ext: ExtControlsState,
): Partial<ExtendedSupervisionControls> {
  const payload: Record<string, boolean | number> = {};
  for (const field of EXTENDED_RESTRICTION_FIELDS) {
    const value = ext[field];
    if (value !== null) {
      payload[field] = value;
    }
  }
  return payload as Partial<ExtendedSupervisionControls>;
}
