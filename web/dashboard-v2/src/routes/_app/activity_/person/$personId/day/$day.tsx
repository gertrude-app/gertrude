import { PageHeading } from '@gertrude/ui';
import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import ActivityFeed from '#/components/ActivityFeed';
import DashboardPage from '#/components/DashboardPage';
import { dateFromDayParam, personActivityHref } from '#/lib/activity-helpers';
import { mockActivity } from '#/lib/mock-data/activity';
import { getMockChildById } from '#/lib/mock-data/people-and-devices';
import { formatDate } from '#/lib/utils';

const PersonActivityDayRoute: React.FC = () => {
  const { personId, day } = Route.useParams();
  const person = getMockChildById(personId);
  const personName = person?.name ?? `Child`;
  const dayDate = dateFromDayParam(day);
  const personDayItems = mockActivity.filter(
    (activity) =>
      activity.personId === personId &&
      activity.date.toDateString() === dayDate.toDateString(),
  );

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
        items={personDayItems}
        personName={personName}
        showPersonHeading={false}
      />
    </DashboardPage>
  );
};

export const Route = createFileRoute(`/_app/activity_/person/$personId/day/$day`)({
  component: PersonActivityDayRoute,
});
