import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import ReferralSourcePage from './ReferralSourcePage';

const noop = (): void => {};

const meta = {
  title: 'Account/Pages/Onboarding/Referral Source',
  component: ReferralSourcePage,
  parameters: {
    ...galleryParameters,
    layout: 'fullscreen',
    screenshotsAt: ['mobile', 'desktop'],
  },
};

export default meta;

export const Default = {
  render: () => (
    <StoryScreen>
      <ReferralSourcePage
        otherText={null}
        onOtherTextChange={noop}
        onChoose={noop}
        onSubmitOther={noop}
        onSkip={noop}
      />
    </StoryScreen>
  ),
};

export const SomethingElse = {
  name: 'Something else',
  render: () => (
    <StoryScreen>
      <ReferralSourcePage
        otherText="A podcast about screen time"
        onOtherTextChange={noop}
        onChoose={noop}
        onSubmitOther={noop}
        onSkip={noop}
      />
    </StoryScreen>
  ),
};
