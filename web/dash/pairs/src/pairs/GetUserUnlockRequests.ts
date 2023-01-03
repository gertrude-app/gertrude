// auto-generated, do not edit
import type { RequestStatus } from '../shared';

export namespace GetUserUnlockRequests {
  export type Input = UUID;

  export type Output = Array<{
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
  }>;
}
