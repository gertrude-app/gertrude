import { PageHeading } from '@gertrude/ui';
import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import ActivityFeed from '#/components/ActivityFeed';
import DashboardPage from '#/components/DashboardPage';
import { dateFromDayParam } from '#/lib/activity-helpers';
import { mockActivity } from '#/lib/mock-data/activity';
import { formatDate } from '#/lib/utils';

const ActivityDayRoute: React.FC = () => {
  const { day } = Route.useParams();
  const dayDate = dateFromDayParam(day);
  const thisDayItems = mockActivity.filter(
    (activity) => activity.date.toDateString() === dayDate.toDateString(),
  );

  return (
    <DashboardPage
      heading={
        <PageHeading
          title={formatDate(dayDate)}
          breadcrumbs={[{ text: `All Activity`, href: `/activity` }]}
        />
      }
    >
      <ActivityFeed items={thisDayItems} />
    </DashboardPage>
  );
};

export const Route = createFileRoute(`/_app/activity_/day/$day`)({
  component: ActivityDayRoute,
});
