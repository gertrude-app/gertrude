import type { GetIosDeviceSettings } from '@shared/pairql/src/account';

export type IosDeviceSettingsConfiguration = GetIosDeviceSettings.Output;

export type IosBlockerSettings = NonNullable<IosDeviceSettingsConfiguration[`blocker`]>;

export type IosBlockGroup = IosBlockerSettings[`allBlockGroups`][number];

export type IosProfileSettings = IosBlockerSettings[`profileSettings`];

export type IosPodcastsSettings = NonNullable<IosDeviceSettingsConfiguration[`podcasts`]>;

export type IosPodcastsSubscription = IosPodcastsSettings[`subscription`];

export type IosMusicSettings = NonNullable<IosDeviceSettingsConfiguration[`music`]>;
