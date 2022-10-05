import { ComponentStory, ComponentMeta } from '@storybook/react';
import UnlockRequestsWidget from './UnlockRequestsWidget';
import { withIds } from '../../story-helpers';

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
};

export const JustOne = Template.bind({});
JustOne.args = {
  unlockRequests: [
    {
      id: `1`,
      target: `gitlab.io`,
      userName: `Little Jimmy`,
      comment: `Super cool thing I want`,
      createdAt: new Date(now.getTime() - 0).toISOString(), // now
    },
  ],
};

export const JustTwo = Template.bind({});
JustTwo.args = {
  unlockRequests: withIds([
    {
      target: `gitlab.io`,
      userName: `Little Jimmy`,
      comment: `Super cool thing I want`,
      createdAt: new Date(now.getTime() - 0).toISOString(), // now
    },
    {
      target: `magicschoolbus.com`,
      userName: `Sally`,
      comment: `For science class, thanks ❤️`,
      createdAt: new Date(now.getTime() - 1000 * 60 * 60 * 24 * 7 * 2).toISOString(), // 2 weeks ago
    },
  ]),
};

export const Lots = Template.bind({});
Lots.args = {
  unlockRequests: withIds([
    {
      target: `gitlab.io`,
      userName: `Little Jimmy`,
      comment: `Super cool thing I want`,
      createdAt: new Date(now.getTime() - 0).toISOString(), // now
    },
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
};
