import { ComponentStory, ComponentMeta } from '@storybook/react';
import UnlockRequestsWidget from './UnlockRequestsWidget';

export default {
  title: `Dashboard/Dashboard/Widgets/UnlockRequestsWidget`,
  component: UnlockRequestsWidget,
} as ComponentMeta<typeof UnlockRequestsWidget>;

const Template: ComponentStory<typeof UnlockRequestsWidget> = (args) => (
  <UnlockRequestsWidget {...args} />
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
};

export const JustOne = Template.bind({});
JustOne.args = {
  unlockRequests: [
    {
      url: `gitlab.io`,
      user: `Little Jimmy`,
      comment: `Super cool thing I want`,
      time: new Date(now.getTime() - 0), // now
    },
  ],
};

export const JustTwo = Template.bind({});
JustTwo.args = {
  unlockRequests: [
    {
      url: `gitlab.io`,
      user: `Little Jimmy`,
      comment: `Super cool thing I want`,
      time: new Date(now.getTime() - 0), // now
    },
    {
      url: `magicschoolbus.com`,
      user: `Sally`,
      comment: `For science class, thanks ❤️`,
      time: new Date(now.getTime() - 1000 * 60 * 60 * 24 * 7 * 2), // 2 weeks ago
    },
  ],
};

export const Lots = Template.bind({});
Lots.args = {
  unlockRequests: [
    {
      url: `gitlab.io`,
      user: `Little Jimmy`,
      comment: `Super cool thing I want`,
      time: new Date(now.getTime() - 0), // now
    },
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
};
