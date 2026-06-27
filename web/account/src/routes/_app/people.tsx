import { LoadingDots, PageHeading } from '@gertrude/ui';
import { Link, createFileRoute } from '@tanstack/react-router';
import React from 'react';
import DashboardPage from '#/components/DashboardPage';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useQuery } from '#/pairql/query';

const PeoplePage: React.FC = () => {
  const query = useQuery(Key.people, () => liveClient.getPeople());

  return (
    <DashboardPage heading={<PageHeading title="Protected People" />}>
      {query.isPending ? (
        <LoadingDots />
      ) : query.isError ? (
        <p className="text-red-600">
          {query.error.userMessage ?? `Failed to load people.`}
        </p>
      ) : (
        <ul className="flex flex-col gap-2">
          {query.data.map((person) => (
            <li key={person.id}>
              <Link
                to="/activity/person/$personId"
                params={{ personId: person.id }}
                className="block rounded-xl border border-stone-200 bg-white px-4 py-3 text-stone-900 transition-colors hover:border-stone-300 hover:bg-stone-50"
              >
                {person.name}
              </Link>
            </li>
          ))}
        </ul>
      )}
    </DashboardPage>
  );
};

export const Route = createFileRoute(`/_app/people`)({
  component: PeoplePage,
});
