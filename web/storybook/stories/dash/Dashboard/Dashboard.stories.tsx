import { Dashboard } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { withStatefulChrome } from '../../decorators/StatefulChrome';
import { withIds, time, withIdsAnd, testImgUrl, props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Dashboard/Screen', // eslint-disable-line
  component: Dashboard,
  decorators: [withStatefulChrome],
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof Dashboard>;

type Story = StoryObj<typeof meta>;

// @screenshot: xs/2500,xl
export const Default: Story = props({
  date: new Date(time.stable()),
  startAddDevice: () => {},
  dismissAddDevice: () => {},
  addDeviceRequest: { state: `idle` },
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
    {
      name: `Little Jimmy`,
      status: {
        case: `filterSuspended`,
        resuming: new Date(new Date().getTime() + 7 * 60 * 1000).toISOString(),
      },
      numDevices: 1,
    },
    {
      name: `Sally`,
      status: {
        case: `downtime`,
        ending: new Date(new Date().getTime() + 60 * 60 * 1000).toISOString(),
      },
      numDevices: 2,
    },
    {
      name: `Henry`,
      status: {
        case: `downtimePaused`,
        resuming: new Date(new Date().getTime() + 5 * 60 * 1000).toISOString(),
      },
      numDevices: 3,
    },
    { name: `Humphry`, status: { case: `offline` }, numDevices: 4 },
    { name: `Hon`, status: { case: `filterOff` }, numDevices: 5 },
    { name: `Hilda`, status: { case: `filterOn` }, numDevices: 5 },
  ]),
  userActivitySummaries: withIdsAnd({ numReviewed: 0 }, [
    { name: `Little Jimmy`, numUnreviewed: 245 },
    { name: `Sally`, numUnreviewed: 0 },
    { name: `Henry`, numUnreviewed: 23 },
  ]),
  recentScreenshots: withIds([
    {
      userName: `Little Jimmy`,
      url: testImgUrl(300, 200),
      createdAt: time.now(),
    },
    {
      userName: `Sally`,
      url: testImgUrl(400, 200),
      createdAt: time.subtracting({ minutes: 2 }),
    },
    {
      userName: `Henry`,
      url: testImgUrl(500, 300),
      createdAt: time.subtracting({ minutes: 6 }),
    },
  ]),
  numAdminNotifications: 2,
});

export const NoUnlockRequests: Story = props({
  ...Default.args,
  unlockRequests: [],
});

export const NoUserActivity: Story = props({
  ...Default.args,
  userActivitySummaries: [],
});

// @screenshot: lg
export const NoUserActivityOrUnlockRequests: Story = props({
  ...Default.args,
  userActivitySummaries: [],
  unlockRequests: [],
});

// @screenshot: xs,lg
export const NoUsers: Story = props({
  ...Default.args,
  users: [],
});

// @screenshot: xs,lg
export const NoDevices: Story = props({
  ...Default.args,
  users: withIds([{ name: `Little Jimmy`, status: { case: `filterOn` }, numDevices: 0 }]),
});

// @screenshot: xs,lg
export const NoNotifications: Story = props({
  ...Default.args,
  numAdminNotifications: 0,
});

export default meta;
