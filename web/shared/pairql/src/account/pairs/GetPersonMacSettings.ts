// auto-generated, do not edit
import type { BlockRule } from '../shared';

export namespace GetPersonMacSettings {
  export interface Input {
    personId: UUID;
  }

  export interface Output {
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
      keychains: Array<{
        id: UUID;
        name: string;
        description?: string;
        warning?: string;
        isPublic: boolean;
        numKeys: number;
        schedule?: {
          type: 'active' | 'inactive';
          days: {
            sunday: boolean;
            monday: boolean;
            tuesday: boolean;
            wednesday: boolean;
            thursday: boolean;
            friday: boolean;
            saturday: boolean;
          };
          startTime: {
            hour: number;
            minute: number;
          };
          endTime: {
            hour: number;
            minute: number;
          };
        };
      }>;
      availableKeychains: Array<{
        id: UUID;
        name: string;
        description?: string;
        warning?: string;
        isPublic: boolean;
        numKeys: number;
        schedule?: {
          type: 'active' | 'inactive';
          days: {
            sunday: boolean;
            monday: boolean;
            tuesday: boolean;
            wednesday: boolean;
            thursday: boolean;
            friday: boolean;
            saturday: boolean;
          };
          startTime: {
            hour: number;
            minute: number;
          };
          endTime: {
            hour: number;
            minute: number;
          };
        };
      }>;
      supportsAlwaysBlocked: boolean;
      availableAlwaysBlockedGroups: Array<{
        id: UUID;
        name: string;
        description: string;
        longDescription: string;
      }>;
      alwaysBlockedGroupIds: UUID[];
      customAlwaysBlockedRules: Array<{
        id: UUID;
        rule: BlockRule;
        comment?: string;
      }>;
    };
    hasMacDevices: boolean;
  }
}
