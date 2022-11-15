import { UnlockRequestsWidget } from '@dash/components';
import type { ComponentStory, ComponentMeta } from '@storybook/react';
import { time, withIdsAnd } from '../../story-helpers';

export default {
  title: 'Dashboard/Dashboard/Widgets/UnlockRequests', // eslint-disable-line
  component: UnlockRequestsWidget,
} as ComponentMeta<typeof UnlockRequestsWidget>;

const Template: ComponentStory<typeof UnlockRequestsWidget> = (args) => (
  <UnlockRequestsWidget {...args} />
);

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
};

export const JustOne = Template.bind({});
JustOne.args = {
  unlockRequests: [
    {
      id: `1`,
      userId: `user1`,
      target: `gitlab.io`,
      userName: `Little Jimmy`,
      comment: `Super cool thing I want`,
      createdAt: time.now(),
    },
  ],
};

export const JustTwo = Template.bind({});
JustTwo.args = {
  unlockRequests: withIdsAnd({ userId: `user1` }, [
    {
      target: `gitlab.io`,
      userName: `Little Jimmy`,
      comment: `Super cool thing I want`,
      createdAt: time.now(),
    },
    {
      target: `magicschoolbus.com`,
      userName: `Sally`,
      comment: `For science class, thanks ❤️`,
      createdAt: time.subtracting({ days: 14 }),
    },
  ]),
};

export const Lots = Template.bind({});
Lots.args = {
  unlockRequests: withIdsAnd({ userId: `user1` }, [
    {
      target: `gitlab.io`,
      userName: `Little Jimmy`,
      comment: `Super cool thing I want`,
      createdAt: time.now(),
    },
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
};
