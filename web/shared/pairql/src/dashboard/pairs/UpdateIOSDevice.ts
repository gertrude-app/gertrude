// auto-generated, do not edit
import type { SuccessOutput, WebPolicy } from '../shared';

export namespace UpdateIOSDevice {
  export interface Input {
    deviceId: UUID;
    enabledBlockGroups: UUID[];
    webPolicy: WebPolicy;
    webPolicyDomains: string[];
  }

  export type Output = SuccessOutput;
}
