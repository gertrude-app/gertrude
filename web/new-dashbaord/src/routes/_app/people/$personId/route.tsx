import { PageHeading, SegmentedTabs } from '@gertrude/ui';
import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import DashboardPage from '#/components/DashboardPage';
import { getPersonSettingsPage, useMockDataSelector } from '#/lib/mock';

const PersonSettingsPage: React.FC = () => {
  const { personId } = Route.useParams();
  const { personName } = useMockDataSelector((db) => getPersonSettingsPage(db, personId));
  const basePath = `/people/${personId}`;

  return (
    <DashboardPage
      heading={
        <PageHeading
          title={personName}
          breadcrumbs={[{ text: `Protected People`, href: `/people` }]}
        />
      }
    >
      <SegmentedTabs
        basePath={basePath}
        tabs={[
          { label: `Basic`, segment: `` },
          { label: `Mac Settings`, segment: `mac-settings` },
          { label: `iPhone/iPad Settings`, segment: `ios-settings` },
        ]}
      />
    </DashboardPage>
  );
};

export const Route = createFileRoute(`/_app/people/$personId`)({
  component: PersonSettingsPage,
});
