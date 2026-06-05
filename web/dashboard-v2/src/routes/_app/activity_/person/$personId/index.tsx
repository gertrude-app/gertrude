import { PageHeading } from '@gertrude/ui';
import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import ActivityOverviewList from '#/components/ActivityOverviewList';
import DashboardPage from '#/components/DashboardPage';
import { personActivityDayHref } from '#/lib/activity-helpers';
import { mockActivity } from '#/lib/mock-data/activity';
import { getMockChildById } from '#/lib/mock-data/people-and-devices';

const PersonActivityPage: React.FC = () => {
  const { personId } = Route.useParams();
  const person = getMockChildById(personId);
  const personName = person?.name ?? `Child`;
  const personActivity = mockActivity.filter(
    (activity) => activity.personId === personId,
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
        activities={personActivity}
        dayHref={(date) => personActivityDayHref(personId, date)}
        emptyText={`No activity to review for ${personName}.`}
      />
    </DashboardPage>
  );
};

export const Route = createFileRoute(`/_app/activity_/person/$personId/`)({
  component: PersonActivityPage,
});
