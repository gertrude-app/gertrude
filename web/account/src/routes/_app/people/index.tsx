import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import type {
  LoadableState,
  PersonCardPerson,
  SuspensionRequest,
} from '#/components/types';
import PeoplePage from '#/components/pages/people/PeoplePage';
import { toPersonCardPerson } from '#/lib/people';
import { toSuspensionRequest } from '#/lib/suspensionRequests';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useQuery } from '#/pairql/query';

const PeopleRoute: React.FC = () => {
  const peopleQuery = useQuery(Key.people, () => liveClient.getPeople());
  const suspensionRequestsQuery = useQuery(Key.suspensionRequests, () =>
    liveClient.getSuspensionRequests(),
  );

  const peopleState: LoadableState<PersonCardPerson[]> =
    peopleQuery.data !== undefined
      ? {
          status: `success`,
          data: peopleQuery.data.map(toPersonCardPerson),
        }
      : peopleQuery.isError
        ? {
            status: `error`,
            message:
              peopleQuery.error.userMessage ?? `Check your connection and try again.`,
            onRetry: () => void peopleQuery.refetch(),
          }
        : { status: `loading` };

  const suspensionRequestsState: LoadableState<SuspensionRequest[]> =
    suspensionRequestsQuery.data !== undefined
      ? {
          status: `success`,
          data: suspensionRequestsQuery.data.map(toSuspensionRequest),
        }
      : suspensionRequestsQuery.isError
        ? {
            status: `error`,
            message:
              suspensionRequestsQuery.error.userMessage ??
              `Check your connection and try again.`,
            onRetry: () => void suspensionRequestsQuery.refetch(),
          }
        : { status: `loading` };

  return (
    <PeoplePage
      peopleState={peopleState}
      suspensionRequestsState={suspensionRequestsState}
      onRefreshSuspensionRequests={() => void suspensionRequestsQuery.refetch()}
      refreshingSuspensionRequests={suspensionRequestsQuery.isFetching}
      suspensionRequestsHref="/requests/suspension"
      suspensionRequestHrefForRequest={(id) => `/requests/suspension/${id}`}
      monitorHref="/activity"
      settingsHrefForPerson={(personId) => `/people/${personId}`}
      monitorHrefForPerson={(personId) => `/activity/person/${personId}`}
    />
  );
};

export const Route = createFileRoute(`/_app/people/`)({
  component: PeopleRoute,
});
