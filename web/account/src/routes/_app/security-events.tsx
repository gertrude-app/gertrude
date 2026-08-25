import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import type { SecurityEventsState } from '#/components/pages/security/SecurityEventsPage';
import type {
  IpLocation,
  SecurityEventFilters,
  SecurityEventSeverity,
  SecurityEventSource,
} from '#/lib/securityEvents';
import SecurityEventsPage from '#/components/pages/security/SecurityEventsPage';
import { getIpLocation, toSecurityEvent } from '#/lib/securityEvents';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useQuery } from '#/pairql/query';

interface SecurityEventsSearch {
  priority?: string;
  source?: string;
}

const severities: SecurityEventSeverity[] = [`high`, `medium`, `low`];
const sources: SecurityEventSource[] = [`mac-app`, `account`];

function parseValues<Value extends string>(value: unknown, allowed: Value[]): Value[] {
  if (typeof value !== `string`) return [];
  return Array.from(
    new Set(
      value
        .split(`,`)
        .filter((candidate): candidate is Value => allowed.includes(candidate as Value)),
    ),
  );
}

function toSearch(filters: SecurityEventFilters): SecurityEventsSearch {
  return {
    priority: filters.severities.length > 0 ? filters.severities.join(`,`) : undefined,
    source: filters.sources.length > 0 ? filters.sources.join(`,`) : undefined,
  };
}

const SecurityEventsRoute: React.FC = () => {
  const search = Route.useSearch();
  const navigate = Route.useNavigate();
  const query = useQuery(Key.securityEvents, () => liveClient.getSecurityEvents());
  const [locations, setLocations] = React.useState<Record<string, IpLocation>>({});
  const filters: SecurityEventFilters = {
    severities: parseValues(search.priority, severities),
    sources: parseValues(search.source, sources),
  };

  React.useEffect(() => {
    if (!query.data) return;
    let active = true;
    const ipAddresses = new Set(
      query.data.flatMap((event) =>
        event.case === `account` && event.ipAddress ? [event.ipAddress] : [],
      ),
    );

    for (const ipAddress of ipAddresses) {
      void getIpLocation(ipAddress).then((location) => {
        if (active && location) {
          setLocations((current) => ({ ...current, [ipAddress]: location }));
        }
      });
    }

    return () => {
      active = false;
    };
  }, [query.data]);

  const state: SecurityEventsState =
    query.data !== undefined
      ? {
          status: `success`,
          data: query.data.map(toSecurityEvent),
        }
      : query.isError
        ? {
            status: `error`,
            message: query.error.userMessage ?? `Check your connection and try again.`,
            onRetry: () => void query.refetch(),
          }
        : { status: `loading` };

  return (
    <SecurityEventsPage
      state={state}
      filters={filters}
      locations={locations}
      refreshing={query.isFetching && query.data !== undefined}
      onRefresh={() => void query.refetch()}
      onFiltersChange={(nextFilters) => {
        void navigate({ search: toSearch(nextFilters), replace: true });
      }}
    />
  );
};

export const Route = createFileRoute(`/_app/security-events`)({
  validateSearch: (search): SecurityEventsSearch => ({
    priority: typeof search[`priority`] === `string` ? search[`priority`] : undefined,
    source: typeof search[`source`] === `string` ? search[`source`] : undefined,
  }),
  component: SecurityEventsRoute,
});
