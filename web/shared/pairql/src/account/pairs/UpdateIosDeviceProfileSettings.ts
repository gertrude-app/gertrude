// auto-generated, do not edit
import type { SuccessOutput } from '../shared';

export namespace UpdateIosDeviceProfileSettings {
  export interface Input {
    deviceId: UUID;
    preventProtectionRemoval: boolean;
    allowDeletingApps: boolean;
    allowFactoryReset: boolean;
    allowInstallingApps: boolean;
  }

  export type Output = SuccessOutput;
}
