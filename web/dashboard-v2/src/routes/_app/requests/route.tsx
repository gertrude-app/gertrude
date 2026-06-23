import { PageHeading, SegmentedTabs } from '@gertrude/ui';
import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import DashboardPage from '#/components/DashboardPage';
import { getRequestsPage, useMockDataSelector } from '#/lib/mock';

const RequestsPage: React.FC = () => {
  const { suspensionRequestCount, unlockRequestCount } =
    useMockDataSelector(getRequestsPage);

  return (
    <DashboardPage heading={<PageHeading title="Requests" />}>
      <SegmentedTabs
        basePath="/requests"
        tabs={[
          {
            label: `Unlock Requests`,
            segment: `unlock`,
            badgeCount: unlockRequestCount,
          },
          {
            label: `Suspension Requests`,
            segment: `suspension`,
            badgeCount: suspensionRequestCount,
          },
        ]}
      />
    </DashboardPage>
  );
};

export const Route = createFileRoute(`/_app/requests`)({
  component: RequestsPage,
});
