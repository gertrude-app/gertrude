import { PageHeading } from '@gertrude/ui';
import React from 'react';
import DashboardPage from '#/components/layout/DashboardPage';
import SegmentedTabLinks from '#/components/navigation/SegmentedTabLinks';

interface Props {
  email: string;
  selectedHref: string;
  notificationsHref: string;
  billingHref: string;
  onChangePassword: () => void;
  children?: React.ReactNode;
}

const SettingsShellPage: React.FC<Props> = ({
  email,
  selectedHref,
  notificationsHref,
  billingHref,
  onChangePassword,
  children,
}) => (
  <DashboardPage
    heading={
      <PageHeading
        title="Settings"
        subtitle={email}
        buttons={[
          {
            text: `Change password`,
            onClick: onChangePassword,
          },
        ]}
      />
    }
  >
    <SegmentedTabLinks
      selectedHref={selectedHref}
      tabs={[
        { label: `Notifications`, href: notificationsHref },
        { label: `Billing`, href: billingHref },
      ]}
    >
      {children}
    </SegmentedTabLinks>
  </DashboardPage>
);

export default SettingsShellPage;
