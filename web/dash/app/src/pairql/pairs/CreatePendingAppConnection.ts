// auto-generated, do not edit
import type Result from '../../lib/Result';
import { pqlQuery } from '../query';
import { ClientAuth } from '../shared';

export namespace CreatePendingAppConnection {
  export interface Input {
    userId: UUID;
  }

  export interface Output {
    code: number;
  }

  export async function fetch(input: Input): Promise<Result<Output, string>> {
    return pqlQuery<Input, Output>(input, ClientAuth.admin, `CreatePendingAppConnection`);
  }
}
