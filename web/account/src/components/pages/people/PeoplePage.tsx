import { Card, EmptyState, PageHeading, Skeleton, Stack, VStack } from '@gertrude/ui';
import {
  CircleAlertIcon,
  PlusIcon,
  RefreshCwIcon,
  ScanEyeIcon,
  UsersIcon,
} from 'lucide-react';
import React from 'react';
import type {
  LoadableState,
  PersonCardPerson,
  SecurityEvent,
  SuspensionRequest,
} from '#/components/types';
import CardContainer from '#/components/layout/CardContainer';
import DashboardPage from '#/components/layout/DashboardPage';
import PersonCard from '#/components/people/PersonCard';
import RightColumnCard from '#/components/requests/RightColumnCard';
import SecurityEventsPreviewCard from '#/components/requests/SecurityEventsPreviewCard';
import SuspensionRequestsPreviewCard from '#/components/requests/SuspensionRequestsPreviewCard';

interface Props {
  peopleState: LoadableState<PersonCardPerson[]>;
  suspensionRequestsState: LoadableState<SuspensionRequest[]>;
  securityEventsState: LoadableState<SecurityEvent[]>;
  onRefreshSuspensionRequests: () => void;
  refreshingSuspensionRequests?: boolean;
  onRefreshSecurityEvents: () => void;
  refreshingSecurityEvents?: boolean;
  addPersonHref: string;
  suspensionRequestsHref: string;
  suspensionRequestHrefForRequest: (id: string) => string;
  securityEventsHref: string;
  monitorHref: string;
  settingsHrefForPerson: (personId: string) => string;
  monitorHrefForPerson: (personId: string) => string;
}

interface LoadErrorProps {
  title: string;
  message: string;
  onRetry: () => void;
}

const LoadError: React.FC<LoadErrorProps> = ({ title, message, onRetry }) => (
  <div role="alert">
    <EmptyState
      icon={CircleAlertIcon}
      title={title}
      description={message}
      button={{
        text: `Try again`,
        type: `button`,
        onClick: onRetry,
        icon: RefreshCwIcon,
      }}
      className="bg-white"
    />
  </div>
);

const PeopleLoadingState: React.FC = () => (
  <>
    <span role="status" className="sr-only">
      Loading protected people
    </span>
    {[0, 1].map((index) => (
      <Card key={index} preset="big" padding={{ default: 3, '@lg/main': 4 }}>
        <VStack gap={4}>
          <Skeleton className="h-5 w-32" />
          <Skeleton radius="large" className="h-20 w-full" />
        </VStack>
      </Card>
    ))}
  </>
);

interface PeopleContentProps {
  state: LoadableState<PersonCardPerson[]>;
  addPersonHref: string;
  settingsHrefForPerson: (personId: string) => string;
  monitorHrefForPerson: (personId: string) => string;
}

const PeopleContent: React.FC<PeopleContentProps> = ({
  state,
  addPersonHref,
  settingsHrefForPerson,
  monitorHrefForPerson,
}) => {
  if (state.status === `loading`) {
    return <PeopleLoadingState />;
  }

  if (state.status === `error`) {
    return (
      <LoadError
        title="Couldn't load protected people"
        message={state.message}
        onRetry={state.onRetry}
      />
    );
  }

  if (state.data.length === 0) {
    return (
      <EmptyState
        icon={UsersIcon}
        title="No protected people"
        description="No one has been added to this account yet."
        button={{
          text: `Add Person`,
          type: `link`,
          href: addPersonHref,
          icon: PlusIcon,
          variant: `primary`,
        }}
        className="bg-white"
      />
    );
  }

  return state.data.map((person) => (
    <PersonCard
      key={person.id}
      person={person}
      settingsHref={settingsHrefForPerson(person.id)}
      monitorHref={monitorHrefForPerson(person.id)}
    />
  ));
};

const SuspensionRequestsLoadingState: React.FC = () => (
  <RightColumnCard title="Suspension Requests">
    <Card padding={3}>
      <span role="status" className="sr-only">
        Loading suspension requests
      </span>
      <VStack gap={3}>
        <Skeleton className="h-4 w-28" />
        <Skeleton radius="large" className="h-20 w-full" />
      </VStack>
    </Card>
  </RightColumnCard>
);

interface SuspensionRequestsContentProps {
  state: LoadableState<SuspensionRequest[]>;
  onRefresh: () => void;
  refreshing?: boolean;
  viewAllHref: string;
  responseHrefForRequest: (id: string) => string;
}

const SuspensionRequestsContent: React.FC<SuspensionRequestsContentProps> = ({
  state,
  onRefresh,
  refreshing,
  viewAllHref,
  responseHrefForRequest,
}) => {
  if (state.status === `loading`) {
    return <SuspensionRequestsLoadingState />;
  }

  if (state.status === `error`) {
    return (
      <RightColumnCard title="Suspension Requests">
        <LoadError
          title="Couldn't load suspension requests"
          message={state.message}
          onRetry={state.onRetry}
        />
      </RightColumnCard>
    );
  }

  return (
    <SuspensionRequestsPreviewCard
      suspensionRequests={state.data}
      onRefresh={onRefresh}
      refreshing={refreshing}
      viewAllHref={viewAllHref}
      responseHrefForRequest={responseHrefForRequest}
    />
  );
};

const PeoplePage: React.FC<Props> = ({
  peopleState,
  suspensionRequestsState,
  securityEventsState,
  onRefreshSuspensionRequests,
  refreshingSuspensionRequests,
  onRefreshSecurityEvents,
  refreshingSecurityEvents,
  addPersonHref,
  suspensionRequestsHref,
  suspensionRequestHrefForRequest,
  securityEventsHref,
  monitorHref,
  settingsHrefForPerson,
  monitorHrefForPerson,
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
      <CardContainer className="flex flex-grow flex-col gap-4 @xl/main:gap-6">
        <PeopleContent
          state={peopleState}
          addPersonHref={addPersonHref}
          settingsHrefForPerson={settingsHrefForPerson}
          monitorHrefForPerson={monitorHrefForPerson}
        />
      </CardContainer>
      <VStack gap={6} className="shrink-0 @5xl/main:w-72">
        <SuspensionRequestsContent
          state={suspensionRequestsState}
          onRefresh={onRefreshSuspensionRequests}
          refreshing={refreshingSuspensionRequests}
          viewAllHref={suspensionRequestsHref}
          responseHrefForRequest={suspensionRequestHrefForRequest}
        />
        <SecurityEventsPreviewCard
          state={securityEventsState}
          onRefresh={onRefreshSecurityEvents}
          refreshing={refreshingSecurityEvents}
          viewAllHref={securityEventsHref}
        />
      </VStack>
    </Stack>
  </DashboardPage>
);

export default PeoplePage;
