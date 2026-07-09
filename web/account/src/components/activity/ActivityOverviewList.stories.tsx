import {
  StoryCanvas,
  StorySection,
  galleryParameters,
} from '@gertrude/ui/src/storybook/StoryLayout';
import ActivityOverviewList from './ActivityOverviewList';
import { daySummaries } from '#/components/storybook/fixtures';

const meta = {
  title: 'Account/Components/Activity/Activity Overview List',
  component: ActivityOverviewList,
  parameters: { layout: 'fullscreen', screenshotsAt: ['desktop'] },
};

export default meta;

export const States = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas innerClassName="max-w-2xl">
      <StorySection title="All activity" contentClassName="flex-col items-stretch">
        <ActivityOverviewList days={daySummaries} dayLink={{ scope: `all` }} />
      </StorySection>
      <StorySection title="Empty" contentClassName="flex-col items-stretch">
        <ActivityOverviewList
          days={[]}
          dayLink={{ scope: `person`, personId: `person-1` }}
          emptyText="No activity to review for Jude."
        />
      </StorySection>
    </StoryCanvas>
  ),
};
