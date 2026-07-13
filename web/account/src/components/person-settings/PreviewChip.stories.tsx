import {
  StoryCanvas,
  StorySection,
  galleryParameters,
} from '@gertrude/ui/src/storybook/StoryLayout';
import PreviewChip from './PreviewChip';

const meta = {
  title: 'Account/Components/Person Settings/Preview Chip',
  component: PreviewChip,
  parameters: { layout: 'fullscreen' },
};

export default meta;

export const States = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection title="Single value">
        <PreviewChip label="Keylogging" values={[{ text: `On`, color: `violet` }]} />
        <PreviewChip label="Downtime" values={[{ text: `Off`, color: `neutral` }]} />
      </StorySection>
      <StorySection title="Multiple values">
        <PreviewChip
          label="Keychains"
          values={[
            { text: `School`, color: `violet` },
            { text: `Games`, color: `neutral` },
          ]}
        />
        <PreviewChip
          label="Blocked groups"
          values={[
            { text: `Social`, color: `violet` },
            { text: `Search`, color: `violet` },
            { text: `GIFs`, color: `neutral` },
          ]}
        />
      </StorySection>
      <StorySection title="Long text">
        <PreviewChip
          label="Screenshots"
          values={[{ text: `Every 30 seconds`, color: `violet` }]}
        />
        <PreviewChip
          label="Always blocked"
          values={[{ text: `messages.google.com`, color: `neutral` }]}
        />
      </StorySection>
    </StoryCanvas>
  ),
};
