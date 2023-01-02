// auto-generated, do not edit
import type { SuccessOutput } from '../shared';
import type Result from '../../lib/Result';
import { pqlQuery } from '../query';
import { ClientAuth } from '../shared';

export namespace DeleteActivityItems {
  export interface Input {
    keystrokeLineIds: UUID[];
    screenshotIds: UUID[];
  }

  export type Output = SuccessOutput;

  export async function fetch(input: Input): Promise<Result<Output, string>> {
    return pqlQuery<Input, Output>(input, ClientAuth.admin, `DeleteActivityItems`);
  }
}
