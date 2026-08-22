// auto-generated, do not edit
import type { SharedKey, SuccessOutput } from '../shared';

export namespace SaveAccountKey {
  export interface Input {
    keychainId: UUID;
    keyId?: UUID;
    key: SharedKey;
    comment?: string;
    expiration?: ISODateString;
  }

  export type Output = SuccessOutput;
}
