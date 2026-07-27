import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import type { ComponentProps, ReactElement } from 'react';
import PeoplePage from './PeoplePage';
import { people, suspensionRequests } from '#/components/storybook/fixtures';

const noop = (): void => {};

type PeoplePageProps = ComponentProps<typeof PeoplePage>;

const defaultProps: PeoplePageProps = {
  peopleState: { status: `success`, data: people },
  suspensionRequestsState: { status: `success`, data: suspensionRequests },
  onRefreshSuspensionRequests: noop,
  suspensionRequestsHref: `/requests/suspension`,
  suspensionRequestHrefForRequest: (id) => `/requests/suspension/${id}`,
  monitorHref: `/activity`,
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

export const Empty = {
  parameters: galleryParameters,
  render: () =>
    renderPage({
      peopleState: { status: `success`, data: [] },
      suspensionRequestsState: { status: `success`, data: [] },
    }),
};

export const Loading = {
  parameters: galleryParameters,
  render: () =>
    renderPage({
      peopleState: { status: `loading` },
      suspensionRequestsState: { status: `loading` },
    }),
};

export const PeopleLoading = {
  name: 'People loading independently',
  parameters: galleryParameters,
  render: () => renderPage({ peopleState: { status: `loading` } }),
};

export const SuspensionRequestsLoading = {
  name: 'Suspension requests loading independently',
  parameters: galleryParameters,
  render: () => renderPage({ suspensionRequestsState: { status: `loading` } }),
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

export const SuspensionRequestsRefreshing = {
  name: 'Suspension requests refreshing',
  parameters: galleryParameters,
  render: () =>
    renderPage({
      suspensionRequestsState: { status: `success`, data: [] },
      refreshingSuspensionRequests: true,
    }),
};
