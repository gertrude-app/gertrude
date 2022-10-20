import { RequestStatus } from '@shared/dashboard/types/GraphQL';

export interface SuspendFilterRequest {
  id: UUID;
  deviceId: UUID;
  userName: string;
  status: RequestStatus;
  requestedDurationInSeconds: number;
  requestComment?: string;
  createdAt: string;
}
