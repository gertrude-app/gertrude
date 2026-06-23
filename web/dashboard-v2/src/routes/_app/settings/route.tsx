import { PageHeading, SegmentedTabs } from '@gertrude/ui';
import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import DashboardPage from '#/components/DashboardPage';

const SettingsPage: React.FC = () => (
  <DashboardPage
    heading={
      <PageHeading
        title="Settings"
        subtitle="johndoe@example.com"
        buttons={[
          {
            text: `Change password`,
            onClick: () => {},
          },
        ]}
      />
    }
  >
    <SegmentedTabs
      basePath="/settings"
      tabs={[
        { label: `Notifications`, segment: `notifications` },
        { label: `Billing`, segment: `billing` },
      ]}
    />
  </DashboardPage>
);

export const Route = createFileRoute(`/_app/settings`)({
  component: SettingsPage,
});
