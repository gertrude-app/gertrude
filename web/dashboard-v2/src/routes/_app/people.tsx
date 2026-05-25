import React from 'react';
import { PlusIcon, ScanEyeIcon } from 'lucide-react';
import { createFileRoute } from '@tanstack/react-router';
import { PageHeading } from '@gertrude/ui';
import DashboardPage from '#/components/DashboardPage';
import {
  mockChildren,
  mockSecurityEvents,
  mockSuspensionRequests,
  mockUnlockRequests,
} from '#/lib/mock-data';
import PersonCard from '#/components/PersonCard';
import CardContainer from '#/components/CardContainer';
import SecurityEventsPreviewCard from '#/components/SecurityEventsPreviewCard';
import SuspensionRequetsPreviewCard from '#/components/SuspensionRequestsPreviewCard';
import UnlockRequestsPreviewCard from '#/components/UnlockRequestsPreviewCard';

const PeoplePage: React.FC = () => (
  <DashboardPage
    heading={
      <PageHeading
        title="Protected People"
        buttons={[
          {
            text: 'Add Child',
            onClick: () => {},
            variant: 'secondary',
            icon: PlusIcon,
          },
          {
            text: 'Monitor',
            onClick: () => {},
            variant: 'primary',
            icon: ScanEyeIcon,
          },
        ]}
      />
    }
  >
    <div className="flex gap-12">
      <CardContainer className="flex flex-col gap-6 flex-grow">
        {mockChildren.map((c) => (
          <PersonCard person={c} />
        ))}
      </CardContainer>
      <div className="w-72 shrink-0 flex flex-col gap-6">
        <SuspensionRequetsPreviewCard allSuspensionRequests={mockSuspensionRequests} />
        <UnlockRequestsPreviewCard allUnlockRequests={mockUnlockRequests} />
        <SecurityEventsPreviewCard allSecurityEvents={mockSecurityEvents} />
      </div>
    </div>
  </DashboardPage>
);

export const Route = createFileRoute('/_app/people')({
  component: PeoplePage,
});
