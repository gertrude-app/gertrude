import { PageHeading } from '@gertrude/ui';
import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import { formatDate } from '@shared/datetime';
import ActivityFeed from '#/components/activity/ActivityFeed';
import {
  ActivityFeedLoadingState,
  ActivityOverviewLoadingState,
} from '#/components/activity/ActivityLoadingStates';
import ActivityOverviewList from '#/components/activity/ActivityOverviewList';
import DashboardPage from '#/components/layout/DashboardPage';
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
      <DashboardPage
        heading={
          <PageHeading
            title="All Activity"
            subtitle="Items are automatically deleted after 14 days."
          />
        }
      >
        <ActivityOverviewList days={daySummaries} dayLink={{ scope: `all` }} />
      </DashboardPage>
    </StoryScreen>
  ),
};

export const PersonOverview = {
  name: 'Person overview',
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <DashboardPage
        heading={
          <PageHeading
            title="Jude's Activity"
            subtitle="Items are automatically deleted after 14 days."
            breadcrumbs={[{ text: `All Activity`, href: `/activity` }]}
          />
        }
      >
        <ActivityOverviewList
          days={daySummaries}
          dayLink={{ scope: `person`, personId: `person-1` }}
        />
      </DashboardPage>
    </StoryScreen>
  ),
};

export const Day = {
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <DashboardPage
        heading={
          <PageHeading
            title={formatDate(new Date(2026, 6, 3), `long`)}
            breadcrumbs={[{ text: `All Activity`, href: `/activity` }]}
          />
        }
      >
        <ActivityFeed
          items={dayActivityItems}
          onToggleFlag={noop}
          onDelete={noop}
          onDeletePersonActivity={noop}
        />
      </DashboardPage>
    </StoryScreen>
  ),
};

export const PersonDay = {
  name: 'Person day',
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <DashboardPage
        heading={
          <PageHeading
            title={formatDate(new Date(2026, 6, 3), `long`)}
            breadcrumbs={[
              { text: `All Activity`, href: `/activity` },
              { text: `Jude's Activity`, href: `/activity/person/person-1` },
            ]}
          />
        }
      >
        <ActivityFeed
          items={dayActivityItems.filter((item) => item.personName === `Jude`)}
          personName="Jude"
          showPersonHeading={false}
          onToggleFlag={noop}
          onDelete={noop}
          onDeletePersonActivity={noop}
        />
      </DashboardPage>
    </StoryScreen>
  ),
};

export const OverviewLoading = {
  name: 'Overview loading',
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <DashboardPage
        heading={
          <PageHeading
            title="All Activity"
            subtitle="Items are automatically deleted after 14 days."
          />
        }
      >
        <ActivityOverviewLoadingState />
      </DashboardPage>
    </StoryScreen>
  ),
};

export const PersonOverviewLoading = {
  name: 'Person overview loading',
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <DashboardPage
        heading={
          <PageHeading
            title="Activity"
            subtitle="Items are automatically deleted after 14 days."
            breadcrumbs={[{ text: `All Activity`, href: `/activity` }]}
          />
        }
      >
        <ActivityOverviewLoadingState />
      </DashboardPage>
    </StoryScreen>
  ),
};

export const DayLoading = {
  name: 'Day loading',
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <DashboardPage
        heading={
          <PageHeading
            title="July 3, 2026"
            breadcrumbs={[{ text: `All Activity`, href: `/activity` }]}
          />
        }
      >
        <ActivityFeedLoadingState />
      </DashboardPage>
    </StoryScreen>
  ),
};

export const PersonDayLoading = {
  name: 'Person day loading',
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <DashboardPage
        heading={
          <PageHeading
            title="July 3, 2026"
            breadcrumbs={[
              { text: `All Activity`, href: `/activity` },
              { text: `Activity`, href: `/activity/person/person-1` },
            ]}
          />
        }
      >
        <ActivityFeedLoadingState showPersonHeading={false} />
      </DashboardPage>
    </StoryScreen>
  ),
};
