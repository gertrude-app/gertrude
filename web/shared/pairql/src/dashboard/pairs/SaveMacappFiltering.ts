// auto-generated, do not edit
import type { BlockRule, PlainTimeWindow, RuleSchedule, SuccessOutput } from '../shared';

export namespace SaveMacappFiltering {
  export interface Input {
    id: UUID;
    filteringDisabled: boolean;
    downtime?: PlainTimeWindow;
    keychains: Array<{
      id: UUID;
      schedule?: RuleSchedule;
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
