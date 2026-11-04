import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import ChooseAppsPage from './ChooseAppsPage';

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

export const MultipleAppsSelected = {
  name: 'Multiple apps selected',
  render: () => (
    <StoryScreen>
      <ChooseAppsPage
        selectedApps={[`mac`, `music`]}
        onSelectedAppsChange={noop}
        onContinue={noop}
        onSkip={noop}
      />
    </StoryScreen>
  ),
};
