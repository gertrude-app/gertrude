// auto-generated, do not edit
import type { SharedKey, SuccessOutput } from '../shared';

export namespace SaveKey {
  export interface Input {
    isNew: boolean;
    id: UUID;
    keychainId: UUID;
    key: SharedKey;
    comment?: string;
    expiration?: ISODateString;
  }

  export type Output = SuccessOutput;
}
