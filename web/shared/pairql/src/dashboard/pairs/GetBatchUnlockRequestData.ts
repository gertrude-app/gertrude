// auto-generated, do not edit
import type { KeychainSummary, UnlockRequest } from '../shared';

export namespace GetBatchUnlockRequestData {
  export type Input = UUID;

  export interface Output {
    requests: UnlockRequest[];
    keychains: KeychainSummary[];
  }
}
