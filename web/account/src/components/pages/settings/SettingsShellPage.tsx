import { PageHeading, Skeleton, VStack } from '@gertrude/ui';
import { LogOutIcon } from 'lucide-react';
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
          {
            text: `Sign out`,
            href: `/signout`,
            icon: LogOutIcon,
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

export const SettingsTabLoading: React.FC<{ label: string }> = ({ label }) => (
  <VStack gap={4} className="mt-4">
    <span role="status" className="sr-only">
      {label}
    </span>
    <Skeleton className="h-6 w-40" />
    <Skeleton radius="large" className="h-28 w-full" />
    <Skeleton radius="large" className="h-48 w-full" />
  </VStack>
);
