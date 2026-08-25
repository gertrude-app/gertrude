import { PageHeading, Stack, VStack } from '@gertrude/ui';
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
  suspensionRequestHrefForRequest: (id: string) => string;
  onRefreshSuspensionRequests: () => void;
  onRefreshSecurityEvents: () => void;
  unlockRequestsHref: string;
  securityEventsHref?: string;
}

const PeoplePageReference: React.FC<Props> = ({
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
  suspensionRequestHrefForRequest,
  onRefreshSuspensionRequests,
  onRefreshSecurityEvents,
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
    <Stack direction={{ default: `vertical`, '@5xl/main': `horizontal` }} gap={12}>
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
      <VStack gap={6} className="@5xl/main:w-72 shrink-0">
        <SuspensionRequestsPreviewCard
          suspensionRequests={suspensionRequests}
          onRefresh={onRefreshSuspensionRequests}
          viewAllHref={suspensionRequestsHref}
          responseHrefForRequest={suspensionRequestHrefForRequest}
        />
        <UnlockRequestsPreviewCard
          unlockRequests={unlockRequests}
          viewAllHref={unlockRequestsHref}
        />
        <SecurityEventsPreviewCard
          state={{ status: `success`, data: securityEvents }}
          onRefresh={onRefreshSecurityEvents}
          viewAllHref={securityEventsHref}
        />
      </VStack>
    </Stack>
  </DashboardPage>
);

export default PeoplePageReference;
