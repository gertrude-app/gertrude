// auto-generated, do not edit
import type { DeviceModelFamily } from '../shared';

export namespace GetUser {
  export type Input = UUID;

  export interface Output {
    id: UUID;
    name: string;
    keyloggingEnabled: boolean;
    screenshotsEnabled: boolean;
    screenshotsResolution: number;
    screenshotsFrequency: number;
    keychains: Array<{
      id: UUID;
      authorId: UUID;
      name: string;
      description?: string;
      isPublic: boolean;
      numKeys: number;
    }>;
    devices: Array<{
      id: UUID;
      isOnline: boolean;
      modelFamily: DeviceModelFamily;
      modelTitle: string;
    }>;
    createdAt: ISODateString;
  }
}
