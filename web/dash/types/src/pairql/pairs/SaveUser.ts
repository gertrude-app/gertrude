// auto-generated, do not edit
import type { SuccessOutput } from '../shared';

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
    keychainIds: UUID[];
  }

  export type Output = SuccessOutput;
}
