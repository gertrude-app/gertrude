// auto-generated, do not edit
import type { SharedKey } from '../shared';

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
}
