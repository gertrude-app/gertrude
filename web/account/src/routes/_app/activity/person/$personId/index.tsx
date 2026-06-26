import { LoadingDots, PageHeading } from '@gertrude/ui';
import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import ActivityOverviewList from '#/components/ActivityOverviewList';
import DashboardPage from '#/components/DashboardPage';
import { toDaySummaries } from '#/lib/activity';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useQuery } from '#/pairql/query';

const TIME_ZONE = Intl.DateTimeFormat().resolvedOptions().timeZone;

const PersonActivityPage: React.FC = () => {
  const { personId } = Route.useParams();
  const query = useQuery(Key.personActivitySummaries(personId), () =>
    liveClient.getPersonActivitySummaries({ personId, timeZone: TIME_ZONE }),
  );

  return (
    <DashboardPage
      heading={
        <PageHeading
          title={query.data ? `${query.data.personName}'s Activity` : `Activity`}
          subtitle="Items are automatically deleted after 14 days."
          breadcrumbs={[{ text: `All Activity`, href: `/activity` }]}
        />
      }
    >
      {query.isPending ? (
        <LoadingDots />
      ) : query.isError ? (
        <p className="text-red-600">
          {query.error.userMessage ?? `Failed to load activity.`}
        </p>
      ) : (
        <ActivityOverviewList
          dayLink={{ scope: `person`, personId }}
          days={toDaySummaries(query.data.days)}
          emptyText={`No activity to review for ${query.data.personName}.`}
        />
      )}
    </DashboardPage>
  );
};

export const Route = createFileRoute(`/_app/activity/person/$personId/`)({
  component: PersonActivityPage,
});
