// auto-generated, do not edit
import type { BlockRule, SuccessOutput } from '../shared';

export namespace UpdatePersonMacInternetFiltering {
  export interface Input {
    personId: UUID;
    filteringEnabled: boolean;
    keychains: Array<{
      id: UUID;
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
    alwaysBlockedGroupIds: UUID[];
    customAlwaysBlockedRules: Array<{
      id: UUID;
      rule: BlockRule;
      comment?: string;
    }>;
  }

  export type Output = SuccessOutput;
}
