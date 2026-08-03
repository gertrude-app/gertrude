import { PageHeading } from '@gertrude/ui';
import React from 'react';
import DashboardPage from '#/components/layout/DashboardPage';
import SegmentedTabLinks from '#/components/navigation/SegmentedTabLinks';

interface Props {
  personName: string;
  peopleHref: string;
  baseHref: string;
  selectedHref: string;
  children?: React.ReactNode;
}

const PersonSettingsShellPage: React.FC<Props> = ({
  personName,
  peopleHref,
  baseHref,
  selectedHref,
  children,
}) => (
  <DashboardPage
    heading={
      <PageHeading
        title={personName}
        breadcrumbs={[{ text: `Protected People`, href: peopleHref }]}
      />
    }
  >
    <SegmentedTabLinks
      selectedHref={selectedHref}
      tabs={[
        { label: `Basic`, href: baseHref },
        {
          label: `Mac`,
          href: `${baseHref}/mac-settings`,
        },
        {
          label: `iPhone/iPad`,
          href: `${baseHref}/ios-settings`,
          badgeText: `Coming soon`,
        },
      ]}
    >
      {children}
    </SegmentedTabLinks>
  </DashboardPage>
);

export default PersonSettingsShellPage;
