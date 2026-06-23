import { PageHeading } from '@gertrude/ui';
import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import ActivityFeed from '#/components/ActivityFeed';
import DashboardPage from '#/components/DashboardPage';
import { dateFromDayParam } from '#/lib/activity-helpers';
import { getActivityDayPage, useMockData } from '#/lib/mock';
import { formatDate } from '#/lib/utils';

const ActivityDayRoute: React.FC = () => {
  const { day } = Route.useParams();
  const { db, dispatch } = useMockData();
  const dayDate = dateFromDayParam(day);
  const { items } = getActivityDayPage(db, dayDate);

  return (
    <DashboardPage
      heading={
        <PageHeading
          title={formatDate(dayDate)}
          breadcrumbs={[{ text: `All Activity`, href: `/activity` }]}
        />
      }
    >
      <ActivityFeed
        items={items}
        onToggleFlag={(id) => dispatch({ type: `activity.toggleFlag`, id })}
        onDelete={(id) => dispatch({ type: `activity.delete`, id })}
        onDeletePersonActivity={(personId) =>
          dispatch({ type: `activity.deleteForPerson`, personId })
        }
      />
    </DashboardPage>
  );
};

export const Route = createFileRoute(`/_app/activity_/day/$day`)({
  component: ActivityDayRoute,
});
