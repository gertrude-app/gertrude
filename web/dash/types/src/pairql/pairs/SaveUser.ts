// auto-generated, do not edit
import type { KeychainSchedule, SuccessOutput, PlainTimeWindow } from '../shared';

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
    downtime?: PlainTimeWindow;
    keychains: Array<{
      id: UUID;
      schedule?: KeychainSchedule;
    }>;
  }

  export type Output = SuccessOutput;
}
