// auto-generated, do not edit
import type { RequestStatus, SuccessOutput } from '../shared';

export namespace UpdateUnlockRequest {
  export interface Input {
    id: UUID;
    responseComment?: string;
    status: RequestStatus;
  }

  export type Output = SuccessOutput;
}
