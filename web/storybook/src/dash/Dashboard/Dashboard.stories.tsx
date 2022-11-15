import { Dashboard } from '@dash/components';
import type { ComponentStory, ComponentMeta } from '@storybook/react';
import { withStatefulChrome } from '../../decorators/StatefulChrome';
import { withIds, time, withIdsAnd } from '../../story-helpers';

export default {
  title: 'Dashboard/Dashboard/Screen', // eslint-disable-line
  component: Dashboard,
  decorators: [withStatefulChrome],
  parameters: { layout: `fullscreen` },
} as ComponentMeta<typeof Dashboard>;

const Template: ComponentStory<typeof Dashboard> = (args) => <Dashboard {...args} />;

// @screenshot: xs/2500,xl
export const Default = Template.bind({});
Default.args = {
  unlockRequests: withIdsAnd({ userId: `user1` }, [
    {
      target: `gitlab.io`,
      userName: `Little Jimmy`,
      comment: `Super cool thing I want`,
      createdAt: time.now(),
    },
    {
      target: `goats.com`,
      userName: `Henry`,
      createdAt: time.subtracting({ minutes: 2 }),
    },
    {
      target: `github.com`,
      userName: `Little Jimmy`,
      createdAt: time.subtracting({ days: 1 }),
    },
    {
      target: `magicschoolbus.com`,
      userName: `Sally`,
      comment: `For science class, thanks ❤️`,
      createdAt: time.subtracting({ days: 14 }),
    },
  ]),
  users: withIds([
    { name: `Little Jimmy`, isOnline: true },
    { name: `Sally`, isOnline: true },
    { name: `Henry`, isOnline: false },
  ]),
  userActivity: withIds([
    { userName: `Little Jimmy`, numUnreviewed: 245 },
    { userName: `Sally`, numUnreviewed: 0 },
    { userName: `Henry`, numUnreviewed: 23 },
  ]),
  userScreenshots: withIds([
    {
      userName: `Little Jimmy`,
      url: `https://placekitten.com/300/200`,
      createdAt: time.now(),
    },
    {
      userName: `Sally`,
      url: `https://placekitten.com/400/200`,
      createdAt: time.subtracting({ minutes: 2 }),
    },
    {
      userName: `Henry`,
      url: `https://placekitten.com/500/300`,
      createdAt: time.subtracting({ minutes: 6 }),
    },
  ]),
};

export const NoUnlockRequests = Template.bind({});
NoUnlockRequests.args = {
  ...Default.args,
  unlockRequests: [],
};

export const NoUserActivity = Template.bind({});
NoUserActivity.args = {
  ...Default.args,
  userActivity: [],
};

// @screenshot: lg
export const NoUserActivityOrUnlockRequests = Template.bind({});
NoUserActivityOrUnlockRequests.args = {
  ...Default.args,
  userActivity: [],
  unlockRequests: [],
};

// @screenshot: xs,lg
export const NoUsers = Template.bind({});
NoUsers.args = {
  ...Default.args,
  users: [],
};
