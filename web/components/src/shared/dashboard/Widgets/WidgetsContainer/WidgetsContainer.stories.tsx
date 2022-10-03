import { ComponentStory, ComponentMeta } from '@storybook/react';
import { withStatefulChrome } from '../../../../decorators/StatefulChrome';
import WidgetsContainer from './WidgetsContainer';

export default {
  title: `Dashboard/Dashboard/WidgetsContainer`,
  component: WidgetsContainer,
  decorators: [withStatefulChrome],
  parameters: { layout: `fullscreen` },
} as ComponentMeta<typeof WidgetsContainer>;

const Template: ComponentStory<typeof WidgetsContainer> = (args) => (
  <WidgetsContainer {...args} />
);

const now = new Date();
export const Default = Template.bind({});
Default.args = {
  unlockRequests: [
    {
      url: `gitlab.io`,
      user: `Little Jimmy`,
      comment: `Super cool thing I want`,
      time: new Date(now.getTime() - 0), // now
    },
    {
      url: `goats.com`,
      user: `Henry`,
      time: new Date(now.getTime() - 1000 * 120), // 2 minutes ago
    },
    {
      url: `github.com`,
      user: `Little Jimmy`,
      time: new Date(now.getTime() - 1000 * 60 * 60 * 24), // 1 day ago
    },
    {
      url: `magicschoolbus.com`,
      user: `Sally`,
      comment: `For science class, thanks ❤️`,
      time: new Date(now.getTime() - 1000 * 60 * 60 * 24 * 7 * 2), // 2 weeks ago
    },
  ],
  users: [
    { name: `Little Jimmy`, online: true },
    { name: `Sally`, online: true },
    { name: `Henry`, online: false },
  ],
  userActivity: [
    { user: `Little Jimmy`, unreviewedItems: 245 },
    { user: `Sally`, unreviewedItems: 0 },
    { user: `Henry`, unreviewedItems: 23 },
  ],
  userScreenshots: [
    {
      userName: `Little Jimmy`,
      img: `https://placekitten.com/300/200`,
      app: `Firefox`,
      time: new Date(),
    },
    {
      userName: `Sally`,
      img: `https://placekitten.com/400/200`,
      app: `Figma`,
      time: new Date(now.getTime() - 1000 * 120),
    },
    {
      userName: `Henry`,
      img: `https://placekitten.com/500/300`,
      app: `Notes`,
      time: new Date(now.getTime() - 1000 * 60),
    },
  ],
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
