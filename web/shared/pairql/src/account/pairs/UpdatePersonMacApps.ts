// auto-generated, do not edit
import type { SingleAppScope, SuccessOutput } from '../shared';

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
      scope: SingleAppScope;
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
