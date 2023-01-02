// auto-generated, do not edit
import type { DeviceModelFamily } from '../shared';
import type Result from '../../lib/Result';
import { pqlQuery } from '../query';
import { ClientAuth } from '../shared';

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

  export async function fetch(input: Input): Promise<Result<Output, string>> {
    return pqlQuery<Input, Output>(input, ClientAuth.admin, `GetUser`);
  }
}
