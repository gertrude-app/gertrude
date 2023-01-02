// auto-generated, do not edit
import type Result from '../../lib/Result';
import { pqlQuery } from '../query';
import { ClientAuth } from '../shared';

export namespace LoginMagicLink {
  export interface Input {
    token: UUID;
  }

  export interface Output {
    token: UUID;
    adminId: UUID;
  }

  export async function fetch(input: Input): Promise<Result<Output, string>> {
    return pqlQuery<Input, Output>(input, ClientAuth.none, `LoginMagicLink`);
  }
}
