import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import ActivityFeedPage from './ActivityFeedPage';
import ActivityOverviewPage from './ActivityOverviewPage';
import { activityItems, daySummaries } from '#/components/storybook/fixtures';

const noop = (): void => {};

const meta = {
  title: 'Account/Pages/Activity',
  parameters: { layout: 'fullscreen' },
};

export default meta;

export const Overview = {
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <ActivityOverviewPage
        title="All Activity"
        subtitle="Items are automatically deleted after 14 days."
        days={daySummaries}
        dayLink={{ scope: `all` }}
      />
    </StoryScreen>
  ),
};

export const Day = {
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <ActivityFeedPage
        date={new Date(2026, 6, 3)}
        items={activityItems}
        breadcrumbs={[{ text: `All Activity`, href: `/activity` }]}
        onToggleFlag={noop}
        onDelete={noop}
        onDeletePersonActivity={noop}
      />
    </StoryScreen>
  ),
};
