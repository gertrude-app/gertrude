import type { CustomAlwaysBlockedRule, Schedule } from '#/components/types';

export interface MacKeychain {
  id: string;
  name: string;
  description?: string;
  warning?: string;
  isPublic: boolean;
  numKeys: number;
  schedule?: Schedule;
}

interface AlwaysBlockedGroup {
  id: string;
  name: string;
  description: string;
  longDescription: string;
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
    keychains: MacKeychain[];
    availableKeychains: MacKeychain[];
    supportsAlwaysBlocked: boolean;
    availableAlwaysBlockedGroups: AlwaysBlockedGroup[];
    alwaysBlockedGroupIds: string[];
    customAlwaysBlockedRules: CustomAlwaysBlockedRule[];
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

export interface InternetFilteringConfiguration {
  filteringEnabled: boolean;
  keychains: Array<{ id: string; schedule?: Schedule }>;
  alwaysBlockedGroupIds: string[];
  customAlwaysBlockedRules: CustomAlwaysBlockedRule[];
}
