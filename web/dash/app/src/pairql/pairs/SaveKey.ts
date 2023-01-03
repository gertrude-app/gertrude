// auto-generated, do not edit
import type { SharedKey, SuccessOutput } from '../shared';
import type Result from '../../lib/Result';
import { pqlQuery } from '../query';
import { ClientAuth } from '../shared';

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

  export async function fetch(input: Input): Promise<Result<Output, string>> {
    return pqlQuery<Input, Output>(input, ClientAuth.admin, `SaveKey`);
  }
}
