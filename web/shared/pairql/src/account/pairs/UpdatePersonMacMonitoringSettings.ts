// auto-generated, do not edit
import type { SuccessOutput } from '../shared';

export namespace UpdatePersonMacMonitoringSettings {
  export interface Input {
    personId: UUID;
    keyloggingEnabled: boolean;
    showSuspensionActivity: boolean;
    screenshotsEnabled: boolean;
    screenshotsResolution: number;
    screenshotsFrequency: number;
  }

  export type Output = SuccessOutput;
}
