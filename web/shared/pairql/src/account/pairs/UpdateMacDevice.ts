// auto-generated, do not edit
import type { ReleaseChannel, SuccessOutput } from '../shared';

export namespace UpdateMacDevice {
  export interface Input {
    deviceId: UUID;
    name?: string;
    releaseChannel: ReleaseChannel;
  }

  export type Output = SuccessOutput;
}
