// auto-generated, do not edit
import type { SharedKey, SingleAppScope } from '../shared';

export namespace DecideUnlockRequests {
  export interface Input {
    personId: UUID;
    decisions: Array<{
      requestIds: UUID[];
      action:
        | {
            case: 'acceptedKey';
            keychainId?: UUID;
            key: SharedKey;
            comment?: string;
            expiration?: ISODateString;
          }
        | {
            case: 'acceptedApp';
            scope: SingleAppScope;
          }
        | {
            case: 'rejected';
          };
    }>;
    responseComment?: string;
  }

  export interface Output {
    handledCount: number;
    skippedCount: number;
    remainingCount: number;
  }
}
