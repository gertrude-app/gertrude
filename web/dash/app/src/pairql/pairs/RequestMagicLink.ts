// auto-generated, do not edit
import type { SuccessOutput } from '../shared';
import type Result from '../../lib/Result';
import { pqlQuery } from '../query';
import { ClientAuth } from '../shared';

export namespace RequestMagicLink {
  export interface Input {
    email: string;
    redirect?: string;
  }

  export type Output = SuccessOutput;

  export async function fetch(input: Input): Promise<Result<Output, string>> {
    return pqlQuery<Input, Output>(input, ClientAuth.none, `RequestMagicLink`);
  }
}
