import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import type { ComponentProps, ReactElement } from 'react';
import SecurityEventsPage from './SecurityEventsPage';
import { securityEvents } from '#/components/storybook/fixtures';

const noop = (): void => {};
const now = new Date(2026, 6, 3, 12);

type SecurityEventsPageProps = ComponentProps<typeof SecurityEventsPage>;

const defaultProps: SecurityEventsPageProps = {
  state: { status: `success`, data: securityEvents },
  filters: { severities: [], sources: [] },
  locations: {
    '203.0.113.42': { city: `Wadsworth`, region: `Ohio`, countryCode: `US` },
    '198.51.100.17': { city: `Chicago`, region: `Illinois`, countryCode: `US` },
  },
  onRefresh: noop,
  onFiltersChange: noop,
  now,
};

const renderPage = (overrides: Partial<SecurityEventsPageProps> = {}): ReactElement => (
  <StoryScreen>
    <SecurityEventsPage {...defaultProps} {...overrides} />
  </StoryScreen>
);

const meta = {
  title: 'Account/Pages/Security Events',
  component: SecurityEventsPage,
  parameters: { layout: 'fullscreen', screenshotsAt: ['mobile', 'desktop'] },
};

export default meta;

export const Default = {
  parameters: galleryParameters,
  render: () => renderPage(),
};

export const Filtered = {
  parameters: galleryParameters,
  render: () =>
    renderPage({
      filters: { severities: [`high`, `medium`], sources: [`account`] },
    }),
};

export const Empty = {
  parameters: galleryParameters,
  render: () => renderPage({ state: { status: `success`, data: [] } }),
};

export const NoMatches = {
  name: 'No filter matches',
  parameters: galleryParameters,
  render: () =>
    renderPage({
      filters: { severities: [`high`], sources: [`account`] },
      state: {
        status: `success`,
        data: securityEvents.filter((event) => event.type === `mac-app`),
      },
    }),
};

export const Loading = {
  parameters: galleryParameters,
  render: () => renderPage({ state: { status: `loading` } }),
};

export const Error = {
  parameters: galleryParameters,
  render: () =>
    renderPage({
      state: {
        status: `error`,
        message: `Check your connection and try again.`,
        onRetry: noop,
      },
    }),
};
