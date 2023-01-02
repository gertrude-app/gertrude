// auto-generated, do not edit
import type Result from '../../lib/Result';
import { pqlQuery } from '../query';
import { ClientAuth } from '../shared';

export namespace GetCheckoutUrl {
  export interface Input {
    adminId: UUID;
  }

  export interface Output {
    url?: string;
  }

  export async function fetch(input: Input): Promise<Result<Output, string>> {
    return pqlQuery<Input, Output>(input, ClientAuth.admin, `GetCheckoutUrl`);
  }
}
