import { PageHeading } from '@gertrude/ui';
import { PlusIcon, ScanEyeIcon } from 'lucide-react';
import React from 'react';
import type {
  PersonCardPerson,
  SecurityEvent,
  SuspensionRequest,
  UnlockRequest,
} from '#/components/types';
import CardContainer from '#/components/layout/CardContainer';
import DashboardPage from '#/components/layout/DashboardPage';
import PersonCard from '#/components/people/PersonCard';
import SecurityEventsPreviewCard from '#/components/requests/SecurityEventsPreviewCard';
import SuspensionRequestsPreviewCard from '#/components/requests/SuspensionRequestsPreviewCard';
import UnlockRequestsPreviewCard from '#/components/requests/UnlockRequestsPreviewCard';

interface Props {
  people: PersonCardPerson[];
  securityEvents: SecurityEvent[];
  suspensionRequests: SuspensionRequest[];
  unlockRequests: UnlockRequest[];
  addPersonHref: string;
  monitorHref: string;
  settingsHrefForPerson: (personId: string) => string;
  monitorHrefForPerson: (personId: string) => string;
  addDeviceHrefForPerson?: (personId: string) => string;
  suspensionRequestsHref: string;
  unlockRequestsHref: string;
  securityEventsHref?: string;
}

const PeoplePage: React.FC<Props> = ({
  people,
  securityEvents,
  suspensionRequests,
  unlockRequests,
  addPersonHref,
  monitorHref,
  settingsHrefForPerson,
  monitorHrefForPerson,
  addDeviceHrefForPerson,
  suspensionRequestsHref,
  unlockRequestsHref,
  securityEventsHref,
}) => (
  <DashboardPage
    heading={
      <PageHeading
        title="Protected People"
        buttons={[
          {
            text: `Add Person`,
            href: addPersonHref,
            variant: `secondary`,
            icon: PlusIcon,
          },
          {
            text: `Monitor`,
            href: monitorHref,
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
          <PersonCard
            key={person.id}
            person={person}
            settingsHref={settingsHrefForPerson(person.id)}
            monitorHref={monitorHrefForPerson(person.id)}
            addDeviceHref={addDeviceHrefForPerson?.(person.id)}
          />
        ))}
      </CardContainer>
      <div className="@5xl/main:w-72 shrink-0 flex flex-col gap-6">
        <SuspensionRequestsPreviewCard
          suspensionRequests={suspensionRequests}
          viewAllHref={suspensionRequestsHref}
        />
        <UnlockRequestsPreviewCard
          unlockRequests={unlockRequests}
          viewAllHref={unlockRequestsHref}
        />
        <SecurityEventsPreviewCard
          securityEvents={securityEvents}
          viewAllHref={securityEventsHref}
        />
      </div>
    </div>
  </DashboardPage>
);

export default PeoplePage;
