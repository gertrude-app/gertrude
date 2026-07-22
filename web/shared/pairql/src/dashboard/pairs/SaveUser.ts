// auto-generated, do not edit
import type {
  BlockRule,
  BlockedMacApp,
  PlainTimeWindow,
  RuleSchedule,
  SuccessOutput,
} from '../shared';

export namespace SaveUser {
  export interface Input {
    id: UUID;
    isNew: boolean;
    name: string;
    keyloggingEnabled: boolean;
    screenshotsEnabled: boolean;
    screenshotsResolution: number;
    screenshotsFrequency: number;
    showSuspensionActivity: boolean;
    filteringDisabled?: boolean;
    downtime?: PlainTimeWindow;
    keychains: Array<{
      id: UUID;
      schedule?: RuleSchedule;
    }>;
    blockedApps?: BlockedMacApp[];
    alwaysBlockedGroupIds?: UUID[];
    customAlwaysBlockedRules?: Array<{
      id: UUID;
      rule: BlockRule;
      comment?: string;
    }>;
  }

  export type Output = SuccessOutput;
}
