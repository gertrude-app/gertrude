import type {
  GetPersonMacSettings,
  UpdatePersonMacApps,
  UpdatePersonMacInternetFiltering,
} from '@shared/pairql/src/account';

type MacSettings = GetPersonMacSettings.Output;
type MacInternetFiltering = MacSettings[`internetFiltering`];
type Flatten<T> = { [K in keyof T]: T[K] };
type Enriched<Row> = Flatten<Row & { name?: string; appIconUrl?: string }>;

export type MacKeychain = MacInternetFiltering[`keychains`][number];

export type DowntimeWindow = NonNullable<MacInternetFiltering[`downtime`]>;

export type MacAppScope = MacSettings[`apps`][`unrestricted`][number][`scope`];

export interface InstalledMacApp {
  id: string;
  name: string;
  bundleId: string;
  identifiedAppSlug?: string;
  appIconUrl?: string;
}

export type BlockedMacApp = Enriched<MacSettings[`apps`][`blocked`][number]>;

export type UnrestrictedMacApp = Enriched<MacSettings[`apps`][`unrestricted`][number]>;

export type PublicUnrestrictedMacApp = Enriched<
  MacSettings[`apps`][`publicUnrestricted`][number]
>;

export type MacSettingsConfiguration = Flatten<
  Omit<MacSettings, `apps`> & {
    apps: {
      blocked: BlockedMacApp[];
      unrestricted: UnrestrictedMacApp[];
      publicUnrestricted: PublicUnrestrictedMacApp[];
    };
  }
>;

export interface MacMonitoringConfiguration {
  keyloggingEnabled: boolean;
  showSuspensionActivity: boolean;
  screenshots: {
    enabled: boolean;
    resolution: number;
    frequency: number;
  };
}

export type MacAppsConfiguration = Omit<UpdatePersonMacApps.Input, `personId`>;

export type InternetFilteringConfiguration = Omit<
  UpdatePersonMacInternetFiltering.Input,
  `personId`
>;
