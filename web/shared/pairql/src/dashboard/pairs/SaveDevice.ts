// auto-generated, do not edit
import type { ReleaseChannel, SuccessOutput } from '../shared';

export namespace SaveDevice {
  export interface Input {
    id: UUID;
    name?: string;
    releaseChannel: ReleaseChannel;
  }

  export type Output = SuccessOutput;
}
