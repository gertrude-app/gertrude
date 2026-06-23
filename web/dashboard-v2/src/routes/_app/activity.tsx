import { PageHeading } from '@gertrude/ui';
import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import ActivityOverviewList from '#/components/ActivityOverviewList';
import DashboardPage from '#/components/DashboardPage';
import { allActivityDayHref } from '#/lib/activity-helpers';
import { getActivityPage, useMockDataSelector } from '#/lib/mock';

const ActivityPage: React.FC = () => {
  const { activities } = useMockDataSelector(getActivityPage);

  return (
    <DashboardPage
      heading={
        <PageHeading
          title="All Activity"
          subtitle="Items are automatically deleted after 14 days."
        />
      }
    >
      <ActivityOverviewList activities={activities} dayHref={allActivityDayHref} />
    </DashboardPage>
  );
};

export const Route = createFileRoute(`/_app/activity`)({
  component: ActivityPage,
});
