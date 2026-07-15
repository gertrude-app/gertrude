import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import ActivityFeedPage from './ActivityFeedPage';
import ActivityOverviewPage from './ActivityOverviewPage';
import { activityItems, daySummaries } from '#/components/storybook/fixtures';

const noop = (): void => {};

const dayActivityItems = activityItems.map((item) => {
  if (item.id === `activity-1`) {
    return { ...item, flagged: true };
  }

  if (item.id === `activity-2b` && item.type === `screenshot`) {
    return {
      ...item,
      url: `/example-screenshots/programmer-200.png`,
      width: 200,
      height: 125,
    };
  }

  if (item.id === `activity-3` && item.type === `screenshot`) {
    return {
      ...item,
      url: `/example-screenshots/google.png`,
      width: 1672,
      height: 941,
    };
  }

  return item;
});

const meta = {
  title: 'Account/Pages/Activity',
  parameters: { layout: 'fullscreen', screenshotsAt: ['mobile', 'desktop'] },
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
        items={dayActivityItems}
        breadcrumbs={[{ text: `All Activity`, href: `/activity` }]}
        onToggleFlag={noop}
        onDelete={noop}
        onDeletePersonActivity={noop}
      />
    </StoryScreen>
  ),
};
