import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import type { ComponentProps, ReactElement } from 'react';
import KeychainsPage from './KeychainsPage';
import { keychains, people } from '#/components/storybook/fixtures';

const noop = async (): Promise<void> => {};

const data = {
  keychains: keychains.slice(0, 3).map((keychain, index) => ({
    ...keychain,
    assignedPersonIds:
      index === 0
        ? people.slice(0, 2).map(({ id }) => id)
        : index === 1
          ? []
          : [people[2]!.id],
  })),
  people: people.map(({ id, name }) => ({ id, name })),
};

type KeychainsPageProps = ComponentProps<typeof KeychainsPage>;

const defaultProps: KeychainsPageProps = {
  state: { status: `success`, data },
  onAssignmentChange: noop,
};

const renderPage = (overrides: Partial<KeychainsPageProps> = {}): ReactElement => (
  <StoryScreen>
    <KeychainsPage {...defaultProps} {...overrides} />
  </StoryScreen>
);

const meta = {
  title: 'Account/Pages/Keychains',
  component: KeychainsPage,
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
      state: { status: `success`, data: { keychains: [], people: data.people } },
    }),
};

export const NoPeople = {
  name: 'No people to assign',
  parameters: galleryParameters,
  render: () =>
    renderPage({
      state: {
        status: `success`,
        data: {
          keychains: data.keychains.map((keychain) => ({
            ...keychain,
            assignedPersonIds: [],
          })),
          people: [],
        },
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
        onRetry: () => {},
      },
    }),
};
