import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import type { SetupApp, SetupStepId } from '#/components/onboarding/setupApps';
import type { PersonCardPerson } from '#/components/types';
import type { ComponentProps, ReactElement } from 'react';
import PeoplePage from './PeoplePage';
import AnnouncementBanner from '#/components/announcements/AnnouncementBanner';
import AuthedAppLayout from '#/components/layout/AuthedAppLayout';
import SetupChecklist from '#/components/onboarding/SetupChecklist';
import { getChecklistSteps } from '#/components/onboarding/setupApps';
import {
  macDevice,
  people,
  securityEvents,
  suspensionRequests,
} from '#/components/storybook/fixtures';

const noop = (): void => {};

type PeoplePageProps = ComponentProps<typeof PeoplePage>;

const defaultProps: PeoplePageProps = {
  peopleState: { status: `success`, data: people },
  suspensionRequestsState: { status: `success`, data: suspensionRequests },
  securityEventsState: { status: `success`, data: securityEvents },
  onRefreshSecurityEvents: noop,
  addPersonHref: `/people/new`,
  unlockRequestSummary: {
    totalCount: 3,
    people: [
      {
        id: people[0]!.id,
        name: people[0]!.name,
        pendingCount: 3,
        targets: [`youtube.com`, `school.example.com`, `scratch.mit.edu`],
      },
    ],
  },
  unlockRequestsHref: `/requests/unlock`,
  unlockRequestHrefForPerson: (personId) => `/requests/unlock/${personId}`,
  suspensionRequestsHref: `/requests/suspension`,
  suspensionRequestHrefForRequest: (id) => `/requests/suspension/${id}`,
  securityEventsHref: `/security-events`,
  monitorHref: `/activity`,
  settingsHrefForPerson: (personId) => `/people/${personId}`,
  monitorHrefForPerson: (personId) => `/activity/person/${personId}`,
};

const renderPage = (overrides: Partial<PeoplePageProps> = {}): ReactElement => (
  <StoryScreen>
    <PeoplePage {...defaultProps} {...overrides} />
  </StoryScreen>
);

const meta = {
  title: 'Account/Pages/People',
  component: PeoplePage,
  parameters: { layout: 'fullscreen', screenshotsAt: ['mobile', 'desktop'] },
};

export default meta;

export const Default = {
  parameters: galleryParameters,
  render: () => renderPage(),
};

export const WithAnnouncement = {
  name: 'With announcement',
  parameters: galleryParameters,
  render: () =>
    renderPage({
      announcement: (
        <AnnouncementBanner
          announcement={{
            id: `people-news`,
            kind: `news`,
            html: `<b>A little more peace of mind.</b> You can now manage all of your protected people and their devices together in Gertrude Account.`,
            action: undefined,
          }}
          onDismiss={noop}
        />
      ),
    }),
};

export const Empty = {
  parameters: galleryParameters,
  render: () =>
    renderPage({
      peopleState: { status: `success`, data: [] },
      unlockRequestSummary: { totalCount: 0, people: [] },
      suspensionRequestsState: { status: `success`, data: [] },
      securityEventsState: { status: `success`, data: [] },
    }),
};

const firstPerson: PersonCardPerson = {
  id: `new-person`,
  name: `Jude`,
  relationship: `child`,
  devices: [],
  screenshot: null,
};

const renderGettingStarted = (
  selectedApps: SetupApp[],
  person?: PersonCardPerson,
  completedSteps: SetupStepId[] = [`person`],
): ReactElement => (
  <AuthedAppLayout
    pathname="/people"
    requestCount={0}
    showMacSection={person?.devices.some((device) => device.type === `mac`) ?? false}
    menuProgress={
      person && {
        completed: completedSteps.length,
        total: getChecklistSteps(selectedApps).length,
      }
    }
    sidebarContent={
      person && (
        <SetupChecklist
          selectedApps={selectedApps}
          completedSteps={completedSteps}
          onSelectStep={noop}
          onChangeApps={noop}
        />
      )
    }
  >
    {renderPage({
      peopleState: { status: `success`, data: person ? [person] : [] },
      unlockRequestSummary: { totalCount: 0, people: [] },
      suspensionRequestsState: { status: `success`, data: [] },
      securityEventsState: { status: `success`, data: [] },
      gettingStarted: { selectedApps, onAddPerson: noop, onChangeApps: noop },
    })}
  </AuthedAppLayout>
);

export const GettingStarted = {
  name: 'Getting started / Mac and Music',
  parameters: galleryParameters,
  render: () => renderGettingStarted([`mac`, `music`]),
};

export const GettingStartedUndecided = {
  name: 'Getting started / Apps undecided',
  parameters: galleryParameters,
  render: () => renderGettingStarted([]),
};

export const GettingStartedPersonAdded = {
  name: 'Getting started / First person added',
  parameters: galleryParameters,
  render: () => renderGettingStarted([`mac`, `music`], firstPerson),
};

export const GettingStartedMacConnected = {
  name: 'Getting started / Mac connected',
  parameters: galleryParameters,
  render: () =>
    renderGettingStarted(
      [`mac`, `music`],
      { ...firstPerson, devices: [{ ...macDevice, personId: firstPerson.id }] },
      [`person`, `mac`],
    ),
};

export const Loading = {
  parameters: galleryParameters,
  render: () =>
    renderPage({
      peopleState: { status: `loading` },
      unlockRequestSummary: undefined,
      suspensionRequestsState: { status: `loading` },
      securityEventsState: { status: `loading` },
    }),
};

export const PeopleLoading = {
  name: 'People loading independently',
  parameters: galleryParameters,
  render: () => renderPage({ peopleState: { status: `loading` } }),
};

export const PeopleError = {
  name: 'People error',
  parameters: galleryParameters,
  render: () =>
    renderPage({
      peopleState: {
        status: `error`,
        message: `Check your connection and try again.`,
        onRetry: noop,
      },
    }),
};

export const SuspensionRequestsError = {
  name: 'Suspension requests error',
  parameters: galleryParameters,
  render: () =>
    renderPage({
      suspensionRequestsState: {
        status: `error`,
        message: `Check your connection and try again.`,
        onRetry: noop,
      },
    }),
};

export const SecurityEventsRefreshing = {
  name: 'Security events refreshing',
  parameters: galleryParameters,
  render: () =>
    renderPage({
      securityEventsState: { status: `success`, data: [] },
      refreshingSecurityEvents: true,
    }),
};
