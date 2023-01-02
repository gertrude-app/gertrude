// auto-generated, do not edit
import type Result from '../../lib/Result';
import { pqlQuery } from '../query';
import { ClientAuth } from '../shared';

export namespace Signup {
  export interface Input {
    email: string;
    password: string;
    signupToken?: string;
  }

  export interface Output {
    url?: string;
  }

  export async function fetch(input: Input): Promise<Result<Output, string>> {
    return pqlQuery<Input, Output>(input, ClientAuth.none, `Signup`);
  }
}
