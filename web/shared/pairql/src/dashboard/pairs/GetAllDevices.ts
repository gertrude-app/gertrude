// auto-generated, do not edit
import type { ChildComputerStatus } from '../shared';

export namespace GetAllDevices {
  export type Input = void;

  export interface Output {
    computers: Array<{
      id: UUID;
      name?: string;
      modelIdentifier: string;
      modelTitle: string;
      users: Array<{
        computerUserId: UUID;
        id: UUID;
        name: string;
        status: ChildComputerStatus;
      }>;
    }>;
    iosDevices: Array<{
      id: UUID;
      childId: UUID;
      childName: string;
      modelName: string;
      deviceType: string;
      iosVersion: string;
      pendingSetup: boolean;
    }>;
  }
}
