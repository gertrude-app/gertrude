import type { RequestStatus } from '@dash/types';

export interface SuspendFilterRequest {
  id: UUID;
  deviceId: UUID;
  userName: string;
  status: RequestStatus;
  requestedDurationInSeconds: number;
  requestComment?: string;
  createdAt: string;
}
