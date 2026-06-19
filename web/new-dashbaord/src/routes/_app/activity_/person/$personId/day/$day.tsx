import { PageHeading } from '@gertrude/ui';
import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import ActivityFeed from '#/components/ActivityFeed';
import DashboardPage from '#/components/DashboardPage';
import { dateFromDayParam, personActivityHref } from '#/lib/activity-helpers';
import { getPersonActivityDayPage, useMockData } from '#/lib/mock';
import { formatDate } from '#/lib/utils';

const PersonActivityDayRoute: React.FC = () => {
  const { personId, day } = Route.useParams();
  const { db, dispatch } = useMockData();
  const dayDate = dateFromDayParam(day);
  const { items, personName } = getPersonActivityDayPage(db, personId, dayDate);

  return (
    <DashboardPage
      heading={
        <PageHeading
          title={formatDate(dayDate)}
          breadcrumbs={[
            { text: `All Activity`, href: `/activity` },
            { text: `${personName}'s Activity`, href: personActivityHref(personId) },
          ]}
        />
      }
    >
      <ActivityFeed
        items={items}
        personName={personName}
        showPersonHeading={false}
        onToggleFlag={(id) => dispatch({ type: `activity.toggleFlag`, id })}
        onDelete={(id) => dispatch({ type: `activity.delete`, id })}
        onDeletePersonActivity={(deletePersonId) =>
          dispatch({ type: `activity.deleteForPerson`, personId: deletePersonId })
        }
      />
    </DashboardPage>
  );
};

export const Route = createFileRoute(`/_app/activity_/person/$personId/day/$day`)({
  component: PersonActivityDayRoute,
});
