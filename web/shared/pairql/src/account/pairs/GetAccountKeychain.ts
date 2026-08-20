// auto-generated, do not edit
import type { SharedKey } from '../shared';

export namespace GetAccountKeychain {
  export interface Input {
    keychainId: UUID;
  }

  export interface Output {
    id: UUID;
    name: string;
    description?: string;
    warning?: string;
    isPublic: boolean;
    keys: Array<{
      id: UUID;
      key: SharedKey;
      comment?: string;
      expiration?: ISODateString;
      appName?: string;
    }>;
  }
}
