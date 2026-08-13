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
      downtime?: {
        start: {
          hour: number;
          minute: number;
        };
        end: {
          hour: number;
          minute: number;
        };
      };
      keychains: Array<{
        id: UUID;
        name: string;
        description?: string;
        warning?: string;
        isPublic: boolean;
        isOwn: boolean;
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
        isOwn: boolean;
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
    apps: {
      blocked: Array<{
        id: UUID;
        identifier: string;
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
      unrestricted: Array<{
        id: UUID;
        scope:
          | {
              type: 'bundleId';
              bundleId: string;
            }
          | {
              type: 'identifiedAppSlug';
              identifiedAppSlug: string;
            };
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
      publicUnrestricted: Array<{
        keychainId: UUID;
        keychainName: string;
        scope:
          | {
              type: 'bundleId';
              bundleId: string;
            }
          | {
              type: 'identifiedAppSlug';
              identifiedAppSlug: string;
            };
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
    };
    hasMacDevices: boolean;
  }
}
