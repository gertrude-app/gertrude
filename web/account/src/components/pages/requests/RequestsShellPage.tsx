import { PageHeading } from '@gertrude/ui';
import React from 'react';
import DashboardPage from '#/components/layout/DashboardPage';
import SegmentedTabLinks from '#/components/navigation/SegmentedTabLinks';

interface Props {
  selectedHref: string;
  unlockRequestsHref: string;
  suspensionRequestsHref: string;
  unlockRequestCount: number;
  suspensionRequestCount: number;
  children?: React.ReactNode;
}

const RequestsShellPage: React.FC<Props> = ({
  selectedHref,
  unlockRequestsHref,
  suspensionRequestsHref,
  unlockRequestCount,
  suspensionRequestCount,
  children,
}) => (
  <DashboardPage heading={<PageHeading title="Requests" />}>
    <SegmentedTabLinks
      selectedHref={selectedHref}
      tabs={[
        {
          label: `Unlock Requests`,
          href: unlockRequestsHref,
          badgeCount: unlockRequestCount,
        },
        {
          label: `Suspension Requests`,
          href: suspensionRequestsHref,
          badgeCount: suspensionRequestCount,
        },
      ]}
    >
      {children}
    </SegmentedTabLinks>
  </DashboardPage>
);

export default RequestsShellPage;
