// auto-generated, do not edit
import type { RequestStatus } from '../shared';
import type Result from '../../lib/Result';
import { pqlQuery } from '../query';
import { ClientAuth } from '../shared';

export namespace GetSuspendFilterRequest {
  export type Input = UUID;

  export interface Output {
    id: UUID;
    deviceId: UUID;
    userName: string;
    requestedDurationInSeconds: number;
    requestComment?: string;
    status: RequestStatus;
    createdAt: ISODateString;
  }

  export async function fetch(input: Input): Promise<Result<Output, string>> {
    return pqlQuery<Input, Output>(input, ClientAuth.admin, `GetSuspendFilterRequest`);
  }
}
