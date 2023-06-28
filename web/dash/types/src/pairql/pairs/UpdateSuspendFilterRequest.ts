// auto-generated, do not edit
import type { SuccessOutput, RequestStatus } from '../shared';

export namespace UpdateSuspendFilterRequest {
  export interface Input {
    id: UUID;
    durationInSeconds: number;
    responseComment?: string;
    status: RequestStatus;
  }

  export type Output = SuccessOutput;
}
