// auto-generated, do not edit
import type { SharedKey } from '../shared';
import type Result from '../../lib/Result';
import { pqlQuery } from '../query';
import { ClientAuth } from '../shared';

export namespace GetAdminKeychain {
  export type Input = UUID;

  export interface Keychain {
    id: UUID;
    name: string;
    description?: string;
    isPublic: boolean;
    authorId: UUID;
    keys: Array<Key>;
  }

  export interface Key {
    id: UUID;
    comment?: string;
    expiration?: ISODateString;
    key: SharedKey;
  }

  Keychain;

  export async function fetch(input: Input): Promise<Result<Output, string>> {
    return pqlQuery<Input, Output>(input, ClientAuth.admin, `GetAdminKeychain`);
  }
}
