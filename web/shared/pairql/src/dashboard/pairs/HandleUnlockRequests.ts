// auto-generated, do not edit
import type { RequestStatus, SharedKey, SingleAppScope, SuccessOutput } from '../shared';

export namespace HandleUnlockRequests {
  export interface Input {
    decisions: Array<{
      unlockRequestId: UUID;
      status: RequestStatus;
      key?: {
        keychainId: UUID;
        key: SharedKey;
        comment?: string;
        expiration?: ISODateString;
      };
      grantAppScope?: SingleAppScope;
      responseComment?: string;
    }>;
    duplicateRequestIds: UUID[];
  }

  export type Output = SuccessOutput;
}
