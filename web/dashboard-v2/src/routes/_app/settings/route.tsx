import React from 'react';
import { createFileRoute } from '@tanstack/react-router';
import { PageHeading, SegmentedTabs } from '@gertrude/ui';
import DashboardPage from '#/components/DashboardPage';

const SettingsPage: React.FC = () => {
  return (
    <DashboardPage
      heading={
        <PageHeading
          title="Settings"
          subtitle="johndoe@example.com"
          buttons={[
            {
              text: 'Change password',
              onClick: () => {},
            },
          ]}
        />
      }
    >
      <SegmentedTabs
        basePath="/settings"
        tabs={[
          { label: 'Notifications', segment: 'notifications' },
          { label: 'Billing', segment: 'billing' },
        ]}
      />
    </DashboardPage>
  );
};

export const Route = createFileRoute('/_app/settings')({
  component: SettingsPage,
});
