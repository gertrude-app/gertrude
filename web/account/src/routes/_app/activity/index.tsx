import { LoadingDots, PageHeading } from '@gertrude/ui';
import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import ActivityOverviewList from '#/components/activity/ActivityOverviewList';
import DashboardPage from '#/components/layout/DashboardPage';
import { toDaySummaries } from '#/lib/activity';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useQuery } from '#/pairql/query';

const TIME_ZONE = Intl.DateTimeFormat().resolvedOptions().timeZone;

const ActivityPage: React.FC = () => {
  const query = useQuery(Key.activitySummaries, () =>
    liveClient.getActivitySummaries({ timeZone: TIME_ZONE }),
  );

  return (
    <DashboardPage
      heading={
        <PageHeading
          title="All Activity"
          subtitle="Items are automatically deleted after 14 days."
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
          dayLink={{ scope: `all` }}
          days={toDaySummaries(query.data)}
        />
      )}
    </DashboardPage>
  );
};

export const Route = createFileRoute(`/_app/activity/`)({
  component: ActivityPage,
});
