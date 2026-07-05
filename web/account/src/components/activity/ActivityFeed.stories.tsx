import {
  StoryCanvas,
  StorySection,
  galleryParameters,
} from '@gertrude/ui/src/storybook/StoryLayout';
import ActivityFeed from './ActivityFeed';
import { activityItems } from '#/components/storybook/fixtures';

const noop = (): void => {};

const meta = {
  title: 'Account/Components/Activity/Activity Feed',
  component: ActivityFeed,
  parameters: { layout: 'fullscreen' },
};

export default meta;

export const GroupedAndSinglePerson = {
  name: 'Grouped and single person',
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas innerClassName="max-w-4xl">
      <StorySection title="Grouped people" contentClassName="flex-col items-stretch">
        <ActivityFeed
          items={activityItems}
          onToggleFlag={noop}
          onDelete={noop}
          onDeletePersonActivity={noop}
        />
      </StorySection>
      <StorySection title="Single person" contentClassName="flex-col items-stretch">
        <ActivityFeed
          items={activityItems.filter((item) => item.personName === `Jude`)}
          personName="Jude"
          showPersonHeading={false}
          onToggleFlag={noop}
          onDelete={noop}
          onDeletePersonActivity={noop}
        />
      </StorySection>
    </StoryCanvas>
  ),
};
