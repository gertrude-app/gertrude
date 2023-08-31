// auto-generated, do not edit
import type { SuccessOutput } from '../shared';

export namespace DecideFilterSuspensionRequest {
  export interface Input {
    id: UUID;
    decision:
      | {
          case: 'accepted';
          durationInSeconds: number;
          extraMonitoring?: string;
        }
      | {
          case: 'rejected';
        };
    responseComment?: string;
  }

  export type Output = SuccessOutput;
}
