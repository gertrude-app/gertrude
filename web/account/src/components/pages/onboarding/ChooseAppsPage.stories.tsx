import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import type { ReactElement } from 'react';
import ChooseAppsPage, { type SetupApp } from './ChooseAppsPage';

const noop = (): void => {};

const meta = {
  title: 'Account/Pages/Onboarding/Choose Apps',
  component: ChooseAppsPage,
  parameters: {
    ...galleryParameters,
    layout: 'fullscreen',
    screenshotsAt: ['mobile', 'desktop'],
  },
};

export default meta;

const renderPage = (selectedApps: SetupApp[]): ReactElement => (
  <StoryScreen>
    <ChooseAppsPage
      selectedApps={selectedApps}
      onSelectedAppsChange={noop}
      onContinue={noop}
      onSkip={noop}
    />
  </StoryScreen>
);

export const Default = {
  render: () => renderPage([]),
};

export const MultipleAppsSelected = {
  name: 'Multiple apps selected',
  render: () => renderPage([`mac`, `music`]),
};
