import { relativeTime } from '@shared/datetime';
import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import type {
  LoadableState,
  PersonCardPerson,
  SuspensionRequest,
} from '#/components/types';
import type { GetPeople } from '@shared/pairql/src/account';
import PeoplePage from '#/components/pages/people/PeoplePage';
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
      monitorHrefForPerson={(personId) => `/activity/person/${personId}`}
    />
  );
};

function toPersonCardPerson(person: GetPeople.Output[number]): PersonCardPerson {
  return {
    id: person.id,
    name: person.name,
    devices: person.devices.map((device) =>
      device.case === `mac`
        ? {
            id: device.id,
            personId: person.id,
            type: `mac`,
            name: device.name,
            macOSVersion: device.macOSVersion,
            modelName: device.modelName,
            modelIdentifier: device.modelIdentifier,
            online: device.online,
          }
        : {
            id: device.id,
            personId: person.id,
            type: device.type,
            iOSVersion: device.iOSVersion,
            modelName: device.modelName,
            modelIdentifier: device.modelIdentifier,
          },
    ),
    screenshot: person.screenshot
      ? {
          url: person.screenshot.url,
          recency: relativeTime(person.screenshot.createdAt),
        }
      : null,
  };
}

export const Route = createFileRoute(`/_app/people`)({
  component: PeopleRoute,
});
