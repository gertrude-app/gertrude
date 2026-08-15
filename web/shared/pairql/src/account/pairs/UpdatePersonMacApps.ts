// auto-generated, do not edit
import type { SuccessOutput } from '../shared';

export namespace UpdatePersonMacApps {
  export interface Input {
    personId: UUID;
    blockedApps: Array<{
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
    unrestrictedApps: Array<{
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
  }

  export type Output = SuccessOutput;
}
