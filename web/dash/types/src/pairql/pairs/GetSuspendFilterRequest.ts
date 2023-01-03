// auto-generated, do not edit
import type { RequestStatus } from '../shared';

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
}
