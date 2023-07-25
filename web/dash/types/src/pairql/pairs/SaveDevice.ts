// auto-generated, do not edit
import type { SuccessOutput, ReleaseChannel } from '../shared';

export namespace SaveDevice {
  export interface Input {
    id: UUID;
    name?: string;
    releaseChannel: ReleaseChannel;
  }

  export type Output = SuccessOutput;
}
