import { LoadingDots, PageHeading } from '@gertrude/ui';
import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import type { PersonCardPerson } from '#/components/types';
import type { GetPeople } from '@shared/pairql/src/account';
import DashboardPage from '#/components/layout/DashboardPage';
import PeoplePage from '#/components/pages/people/PeoplePage';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useQuery } from '#/pairql/query';

const PeopleRoute: React.FC = () => {
  const query = useQuery(Key.people, () => liveClient.getPeople());

  if (query.isPending) {
    return (
      <DashboardPage heading={<PageHeading title="Protected People" />}>
        <LoadingDots />
      </DashboardPage>
    );
  }

  if (query.isError) {
    return (
      <DashboardPage heading={<PageHeading title="Protected People" />}>
        <p className="text-red-600">
          {query.error.userMessage ?? `Failed to load people.`}
        </p>
      </DashboardPage>
    );
  }

  return (
    <PeoplePage
      people={query.data.map(toPersonCardPerson)}
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
    screenshot: null,
  };
}

export const Route = createFileRoute(`/_app/people`)({
  component: PeopleRoute,
});
