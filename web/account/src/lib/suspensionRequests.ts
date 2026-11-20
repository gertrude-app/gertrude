import { relativeTime, time } from '@shared/datetime';
import type { SuspensionRequest } from '#/components/types';
import type { GetSuspensionRequests } from '@shared/pairql/src/account';

export function toSuspensionRequest(
  request: GetSuspensionRequests.Output[number],
): SuspensionRequest {
  return {
    id: request.id,
    personId: request.personId,
    personName: request.personName,
    deviceName: request.deviceName,
    requestedDurationInSeconds: request.requestedDurationInSeconds,
    duration: time.humanDuration(request.requestedDurationInSeconds),
    reason: request.reason,
    extraMonitoringOptions: request.extraMonitoringOptions,
    requestedAt: request.createdAt,
  };
}

export function requestAge(requestedAt: string): string {
  return Date.now() - new Date(requestedAt).getTime() < 60_000
    ? `just now`
    : relativeTime(requestedAt);
}
