import {
  StoryCanvas,
  StorySection,
  galleryParameters,
} from '@gertrude/ui/src/storybook/StoryLayout';
import PromoCard from './PromoCard';

const meta = {
  title: 'Account/Components/Promo Card',
  component: PromoCard,
  parameters: { layout: 'fullscreen' },
};

export default meta;

export const TrialOffer = {
  name: 'Trial offer',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <StoryCanvas>
      <StorySection title="Trial offer" contentClassName="block">
        <PromoCard
          primaryText="Try every Mac feature free for 21 days"
          secondaryText="Connecting Gertrude on a Mac requires the Full plan."
          className="max-w-lg"
        />
      </StorySection>
    </StoryCanvas>
  ),
};
