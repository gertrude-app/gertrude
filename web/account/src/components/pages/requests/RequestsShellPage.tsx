import { PageHeading } from '@gertrude/ui';
import React from 'react';
import DashboardPage from '#/components/layout/DashboardPage';
import SegmentedTabLinks from '#/components/navigation/SegmentedTabLinks';

interface Props {
  selected: `unlock` | `suspension`;
  unlockRequestCount?: number;
  suspensionRequestCount?: number;
  children: React.ReactNode;
}

const RequestsShellPage: React.FC<Props> = ({
  selected,
  unlockRequestCount,
  suspensionRequestCount,
  children,
}) => (
  <DashboardPage heading={<PageHeading title="Requests" />}>
    <SegmentedTabLinks
      selectedHref={`/requests/${selected}`}
      tabs={[
        {
          label: `Unlock Requests`,
          href: `/requests/unlock`,
          badgeCount: unlockRequestCount,
        },
        {
          label: `Suspension Requests`,
          href: `/requests/suspension`,
          badgeCount: suspensionRequestCount,
        },
      ]}
    >
      {children}
    </SegmentedTabLinks>
  </DashboardPage>
);

export default RequestsShellPage;
