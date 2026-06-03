import { PageHeading, SegmentedTabs } from '@gertrude/ui';
import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import DashboardPage from '#/components/DashboardPage';
import { mockSuspensionRequests, mockUnlockRequests } from '#/lib/mock-data';

const RequestsPage: React.FC = () => (
  <DashboardPage heading={<PageHeading title="Requests" />}>
    <SegmentedTabs
      basePath="/requests"
      tabs={[
        {
          label: `Unlock Requests`,
          segment: `unlock`,
          badgeCount: mockUnlockRequests.length,
        },
        {
          label: `Suspension Requests`,
          segment: `suspension`,
          badgeCount: mockSuspensionRequests.length,
        },
      ]}
    />
  </DashboardPage>
);

export const Route = createFileRoute(`/_app/requests`)({
  component: RequestsPage,
});
