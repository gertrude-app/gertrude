import { UnlockRequestsWidget } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { time, withIdsAnd, props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Dashboard/Widgets/UnlockRequests', // eslint-disable-line
  component: UnlockRequestsWidget,
} satisfies Meta<typeof UnlockRequestsWidget>;

type Story = StoryObj<typeof meta>;

export const Default: Story = props({
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
});

export const JustOne: Story = props({
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
});

export const JustTwo: Story = props({
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
});

export const Lots: Story = props({
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
});

export default meta;
