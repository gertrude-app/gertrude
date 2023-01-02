// auto-generated, do not edit
import type { RequestStatus } from '../shared';
import type Result from '../../lib/Result';
import { pqlQuery } from '../query';
import { ClientAuth } from '../shared';

export namespace GetUnlockRequest {
  export type Input = UUID;

  export interface Output {
    id: UUID;
    userId: UUID;
    userName: string;
    status: RequestStatus;
    url?: string;
    domain?: string;
    ipAddress?: string;
    requestComment?: string;
    appName?: string;
    appSlug?: string;
    appBundleId?: string;
    appCategories: string[];
    requestProtocol?: string;
    createdAt: ISODateString;
  }

  export async function fetch(input: Input): Promise<Result<Output, string>> {
    return pqlQuery<Input, Output>(input, ClientAuth.admin, `GetUnlockRequest`);
  }
}
