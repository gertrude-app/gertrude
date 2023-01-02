// auto-generated, do not edit
import type { RequestStatus, SuccessOutput } from '../shared';
import type Result from '../../lib/Result';
import { pqlQuery } from '../query';
import { ClientAuth } from '../shared';

export namespace UpdateSuspendFilterRequest {
  export interface Input {
    id: UUID;
    durationInSeconds: number;
    responseComment?: string;
    status: RequestStatus;
  }

  export type Output = SuccessOutput;

  export async function fetch(input: Input): Promise<Result<Output, string>> {
    return pqlQuery<Input, Output>(input, ClientAuth.admin, `UpdateSuspendFilterRequest`);
  }
}
