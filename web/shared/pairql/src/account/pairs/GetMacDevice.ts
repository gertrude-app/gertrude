// auto-generated, do not edit
import type { ChildComputerStatus, ReleaseChannel } from '../shared';

export namespace GetMacDevice {
  export interface Input {
    deviceId: UUID;
  }

  export interface Output {
    id: UUID;
    name?: string;
    modelName: string;
    modelIdentifier: string;
    macOSVersion?: string;
    appVersion?: string;
    releaseChannel: ReleaseChannel;
    targetVersions: {
      stable?: string;
      beta?: string;
      canary?: string;
    };
    people: Array<{
      id: UUID;
      name: string;
      status: ChildComputerStatus;
    }>;
  }
}
