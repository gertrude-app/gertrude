import { PageHeading } from '@gertrude/ui';
import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import ActivityOverviewList from '#/components/ActivityOverviewList';
import DashboardPage from '#/components/DashboardPage';
import { allActivityDayHref } from '#/lib/activity-helpers';
import { mockActivity } from '#/lib/mock-data/activity';

const ActivityPage: React.FC = () => (
  <DashboardPage
    heading={
      <PageHeading
        title="All Activity"
        subtitle="Items are automatically deleted after 14 days."
      />
    }
  >
    <ActivityOverviewList activities={mockActivity} dayHref={allActivityDayHref} />
  </DashboardPage>
);

export const Route = createFileRoute(`/_app/activity`)({
  component: ActivityPage,
});
