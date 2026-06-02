import React from 'react';
import { createFileRoute } from '@tanstack/react-router';
import { PageHeading, SegmentedTabs } from '@gertrude/ui';
import DashboardPage from '#/components/DashboardPage';
import { mockSuspensionRequests, mockUnlockRequests } from '#/lib/mock-data';

const PeopleRequestsPage: React.FC = () => {
  return (
    <DashboardPage
      heading={
        <PageHeading
          title="Requests"
          breadcrumbs={[{ text: 'People', href: '/people' }]}
        />
      }
    >
      <SegmentedTabs
        basePath="/people/requests"
        tabs={[
          {
            label: 'Unlock Requests',
            segment: 'unlock',
            badgeCount: mockUnlockRequests.length,
          },
          {
            label: 'Suspension Requests',
            segment: 'suspension',
            badgeCount: mockSuspensionRequests.length,
          },
        ]}
      />
    </DashboardPage>
  );
};

export const Route = createFileRoute('/_app/people/requests')({
  component: PeopleRequestsPage,
});
