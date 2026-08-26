// auto-generated, do not edit
import type { SuccessOutput } from '../shared';

export namespace UpdateIosDeviceBlockedGroups {
  export interface Input {
    deviceId: UUID;
    enabledBlockGroupIds: UUID[];
  }

  export type Output = SuccessOutput;
}
