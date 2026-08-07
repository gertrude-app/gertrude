// auto-generated, do not edit
import type { SuccessOutput } from '../shared';

export namespace SaveMacappMonitoring {
  export interface Input {
    id: UUID;
    keyloggingEnabled: boolean;
    screenshotsEnabled: boolean;
    screenshotsResolution: number;
    screenshotsFrequency: number;
    showSuspensionActivity: boolean;
  }

  export type Output = SuccessOutput;
}
