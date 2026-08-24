import type { SecurityEvent } from '#/components/types';
import type { GetSecurityEvents } from '@shared/pairql/src/account';

export type SecurityEventSeverity = SecurityEvent[`severity`];
export type SecurityEventSource = SecurityEvent[`type`];

export type SecurityEventFilters = {
  severities: SecurityEventSeverity[];
  sources: SecurityEventSource[];
};

export type IpLocation = {
  city: string;
  region: string;
  countryCode: string;
};

export function toSecurityEvent(event: GetSecurityEvents.Output[number]): SecurityEvent {
  const shared = {
    id: event.id,
    title: event.title,
    detail: event.detail,
    explanation: event.explanation,
    severity: event.severity,
    createdAt: new Date(event.createdAt),
  };

  if (event.case === `macApp`) {
    return {
      ...shared,
      type: `mac-app`,
      personId: event.personId,
      personName: event.personName,
      deviceId: event.deviceId,
      deviceName: event.deviceName,
    };
  }

  return {
    ...shared,
    type: `account`,
    ipAddress: event.ipAddress,
  };
}

export function filterSecurityEvents(
  events: SecurityEvent[],
  filters: SecurityEventFilters,
): SecurityEvent[] {
  return events.filter(
    (event) =>
      (filters.severities.length === 0 || filters.severities.includes(event.severity)) &&
      (filters.sources.length === 0 || filters.sources.includes(event.type)),
  );
}

const locationCache: Record<string, Promise<IpLocation | null>> = {};

export function getIpLocation(ipAddress: string): Promise<IpLocation | null> {
  locationCache[ipAddress] ??= fetch(`https://ipapi.co/${ipAddress}/json/`)
    .then((response) => response.json())
    .then((data: unknown) => {
      if (!isLocationResponse(data)) return null;
      return {
        city: data.city,
        region: data.region,
        countryCode: data.country_code,
      };
    })
    .catch(() => null);

  return locationCache[ipAddress];
}

function isLocationResponse(
  value: unknown,
): value is { city: string; region: string; country_code: string } {
  if (typeof value !== `object` || value === null) return false;
  const data = value as Record<string, unknown>;
  return (
    typeof data[`city`] === `string` &&
    typeof data[`region`] === `string` &&
    typeof data[`country_code`] === `string`
  );
}
