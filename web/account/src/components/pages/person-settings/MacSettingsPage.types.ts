import type { CustomAlwaysBlockedRule, Schedule, TimeOfDay } from '#/components/types';

export interface MacKeychain {
  id: string;
  name: string;
  description?: string;
  warning?: string;
  isPublic: boolean;
  isOwn: boolean;
  numKeys: number;
  schedule?: Schedule;
}

export interface DowntimeWindow {
  start: TimeOfDay;
  end: TimeOfDay;
}

interface AlwaysBlockedGroup {
  id: string;
  name: string;
  description: string;
  longDescription: string;
}

export type MacAppScope =
  | { type: `bundleId`; bundleId: string }
  | { type: `identifiedAppSlug`; identifiedAppSlug: string };

export interface InstalledMacApp {
  id: string;
  name: string;
  bundleId: string;
  identifiedAppSlug?: string;
  appIconUrl?: string;
}

export interface BlockedMacApp {
  id: string;
  identifier: string;
  name?: string;
  appIconUrl?: string;
  schedule?: Schedule;
}

export interface UnrestrictedMacApp {
  id: string;
  scope: MacAppScope;
  name?: string;
  appIconUrl?: string;
  schedule?: Schedule;
}

export interface PublicUnrestrictedMacApp {
  keychainId: string;
  keychainName: string;
  scope: MacAppScope;
  name?: string;
  appIconUrl?: string;
  schedule?: Schedule;
}

export interface MacSettingsConfiguration {
  keyloggingEnabled: boolean;
  showSuspensionActivity: boolean;
  screenshots: {
    enabled: boolean;
    resolution: number;
    frequency: number;
    canBeDisabled: boolean;
  };
  internetFiltering: {
    enabled: boolean;
    canBeDisabled: boolean;
    downtime?: DowntimeWindow;
    keychains: MacKeychain[];
    availableKeychains: MacKeychain[];
    supportsAlwaysBlocked: boolean;
    availableAlwaysBlockedGroups: AlwaysBlockedGroup[];
    alwaysBlockedGroupIds: string[];
    customAlwaysBlockedRules: CustomAlwaysBlockedRule[];
  };
  apps: {
    blocked: BlockedMacApp[];
    unrestricted: UnrestrictedMacApp[];
    publicUnrestricted: PublicUnrestrictedMacApp[];
  };
  hasMacDevices: boolean;
}

export interface MacMonitoringConfiguration {
  keyloggingEnabled: boolean;
  showSuspensionActivity: boolean;
  screenshots: {
    enabled: boolean;
    resolution: number;
    frequency: number;
  };
}

export interface MacAppsConfiguration {
  blockedApps: Array<{
    id: string;
    identifier: string;
    schedule?: Schedule;
  }>;
  unrestrictedApps: Array<{
    id: string;
    scope: MacAppScope;
    schedule?: Schedule;
  }>;
}

export interface InternetFilteringConfiguration {
  filteringEnabled: boolean;
  downtime?: DowntimeWindow;
  keychains: Array<{ id: string; schedule?: Schedule }>;
  alwaysBlockedGroupIds: string[];
  customAlwaysBlockedRules: CustomAlwaysBlockedRule[];
}
