import { ComponentStory, ComponentMeta } from '@storybook/react';
import { withStatefulChrome } from '../../../decorators/StatefulChrome';
import Dashboard from './Dashboard';
import { withIds } from '../story-helpers';

export default {
  title: `Dashboard/Dashboard`,
  component: Dashboard,
  decorators: [withStatefulChrome],
  parameters: { layout: `fullscreen` },
} as ComponentMeta<typeof Dashboard>;

const Template: ComponentStory<typeof Dashboard> = (args) => <Dashboard {...args} />;

const now = new Date();
export const Default = Template.bind({});
Default.args = {
  unlockRequests: withIds([
    {
      target: `gitlab.io`,
      userName: `Little Jimmy`,
      comment: `Super cool thing I want`,
      createdAt: new Date(now.getTime() - 0).toISOString(), // now
    },
    {
      target: `goats.com`,
      userName: `Henry`,
      createdAt: new Date(now.getTime() - 1000 * 120).toISOString(), // 2 minutes ago
    },
    {
      target: `github.com`,
      userName: `Little Jimmy`,
      createdAt: new Date(now.getTime() - 1000 * 60 * 60 * 24).toISOString(), // 1 day ago
    },
    {
      target: `magicschoolbus.com`,
      userName: `Sally`,
      comment: `For science class, thanks ❤️`,
      createdAt: new Date(now.getTime() - 1000 * 60 * 60 * 24 * 7 * 2).toISOString(), // 2 weeks ago
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
      createdAt: new Date().toISOString(),
    },
    {
      userName: `Sally`,
      url: `https://placekitten.com/400/200`,
      createdAt: new Date(now.getTime() - 1000 * 120).toISOString(),
    },
    {
      userName: `Henry`,
      url: `https://placekitten.com/500/300`,
      createdAt: new Date(now.getTime() - 1000 * 60).toISOString(),
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

export const NoUserActivityOrUnlockRequests = Template.bind({});
NoUserActivityOrUnlockRequests.args = {
  ...Default.args,
  userActivity: [],
  unlockRequests: [],
};

export const NoUsers = Template.bind({});
NoUsers.args = {
  ...Default.args,
  users: [],
};
