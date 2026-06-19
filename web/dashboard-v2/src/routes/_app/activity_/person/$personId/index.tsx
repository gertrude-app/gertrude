import { PageHeading } from '@gertrude/ui';
import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import ActivityOverviewList from '#/components/ActivityOverviewList';
import DashboardPage from '#/components/DashboardPage';
import { personActivityDayHref } from '#/lib/activity-helpers';
import { getPersonActivityPage, useMockDataSelector } from '#/lib/mock';

const PersonActivityPage: React.FC = () => {
  const { personId } = Route.useParams();
  const { activities, personName } = useMockDataSelector((db) =>
    getPersonActivityPage(db, personId),
  );

  return (
    <DashboardPage
      heading={
        <PageHeading
          title={`${personName}'s Activity`}
          subtitle="Items are automatically deleted after 14 days."
          breadcrumbs={[{ text: `All Activity`, href: `/activity` }]}
        />
      }
    >
      <ActivityOverviewList
        activities={activities}
        dayHref={(date) => personActivityDayHref(personId, date)}
        emptyText={`No activity to review for ${personName}.`}
      />
    </DashboardPage>
  );
};

export const Route = createFileRoute(`/_app/activity_/person/$personId/`)({
  component: PersonActivityPage,
});
