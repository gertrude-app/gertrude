import { PageHeading } from '@gertrude/ui';
import { createFileRoute } from '@tanstack/react-router';
import { PlusIcon, ScanEyeIcon } from 'lucide-react';
import React from 'react';
import CardContainer from '#/components/CardContainer';
import DashboardPage from '#/components/DashboardPage';
import PersonCard from '#/components/PersonCard';
import SecurityEventsPreviewCard from '#/components/SecurityEventsPreviewCard';
import SuspensionRequetsPreviewCard from '#/components/SuspensionRequestsPreviewCard';
import UnlockRequestsPreviewCard from '#/components/UnlockRequestsPreviewCard';
import { getPeoplePage, useMockDataSelector } from '#/lib/mock';

const PeoplePage: React.FC = () => {
  const { people, securityEvents, suspensionRequests, unlockRequests } =
    useMockDataSelector(getPeoplePage);

  return (
    <DashboardPage
      heading={
        <PageHeading
          title="Protected People"
          buttons={[
            {
              text: `Add Child`,
              onClick: () => {},
              variant: `secondary`,
              icon: PlusIcon,
            },
            {
              text: `Monitor`,
              onClick: () => {},
              variant: `primary`,
              icon: ScanEyeIcon,
            },
          ]}
        />
      }
    >
      <div className="flex flex-col @5xl/main:flex-row gap-12">
        <CardContainer className="flex flex-col gap-4 @xl/main:gap-6 flex-grow">
          {people.map((person) => (
            <PersonCard key={person.id} person={person} />
          ))}
        </CardContainer>
        <div className="@5xl/main:w-72 shrink-0 flex flex-col gap-6">
          <SuspensionRequetsPreviewCard allSuspensionRequests={suspensionRequests} />
          <UnlockRequestsPreviewCard allUnlockRequests={unlockRequests} />
          <SecurityEventsPreviewCard allSecurityEvents={securityEvents} />
        </div>
      </div>
    </DashboardPage>
  );
};

export const Route = createFileRoute(`/_app/people/`)({
  component: PeoplePage,
});
