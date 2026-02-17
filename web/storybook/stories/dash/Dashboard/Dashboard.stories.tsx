import { Dashboard } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { withStatefulChrome } from '../../decorators/StatefulChrome';
import { props, testImgUrl, time, withIds, withIdsAnd } from '../../story-helpers';

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
  dismissAnnouncement: () => {},
  onStartTrial: () => {},
  addDeviceRequest: { state: `idle` },
  unlockRequests: withIdsAnd({ childId: `child1` }, [
    {
      target: `gitlab.io`,
      childName: `Little Jimmy`,
      comment: `Super cool thing I want`,
      createdAt: time.now(),
    },
    {
      target: `goats.com`,
      childName: `Henry`,
      createdAt: time.subtracting({ minutes: 2 }),
    },
    {
      target: `github.com`,
      childName: `Little Jimmy`,
      createdAt: time.subtracting({ days: 1 }),
    },
    {
      target: `magicschoolbus.com`,
      childName: `Sally`,
      comment: `For science class, thanks ❤️`,
      createdAt: time.subtracting({ days: 14 }),
    },
  ]),
  childData: withIds([
    {
      name: `Little Jimmy`,
      devices: [
        {
          platform: `mac`,
          deviceName: `MacBook Pro`,
          macStatus: {
            case: `filterSuspended`,
            resuming: new Date(new Date().getTime() + 7 * 60 * 1000).toISOString(),
          },
        },
      ],
    },
    {
      name: `Sally`,
      devices: [
        {
          platform: `mac`,
          deviceName: `iMac`,
          macStatus: {
            case: `downtime`,
            ending: new Date(new Date().getTime() + 60 * 60 * 1000).toISOString(),
          },
        },
        { platform: `mac`, deviceName: `MacBook Air`, macStatus: { case: `offline` } },
      ],
    },
    {
      name: `Henry`,
      devices: [
        {
          platform: `mac`,
          deviceName: `Mac Mini`,
          macStatus: {
            case: `downtimePaused`,
            resuming: new Date(new Date().getTime() + 5 * 60 * 1000).toISOString(),
          },
        },
        { platform: `mac`, deviceName: `MacBook Pro`, macStatus: { case: `filterOn` } },
        { platform: `ios`, deviceName: `iPhone 14`, iosStatus: `setupComplete` },
      ],
    },
    {
      name: `Humphry`,
      devices: [
        { platform: `mac`, deviceName: `MacBook Air`, macStatus: { case: `offline` } },
      ],
    },
    {
      name: `Hon`,
      devices: [
        { platform: `mac`, deviceName: `iMac`, macStatus: { case: `filterOff` } },
      ],
    },
    {
      name: `Hilda`,
      devices: [
        { platform: `mac`, deviceName: `Mac Mini`, macStatus: { case: `filterOn` } },
      ],
    },
  ]),
  childActivitySummaries: withIdsAnd({ numReviewed: 0 }, [
    { name: `Little Jimmy`, numUnreviewed: 245 },
    { name: `Sally`, numUnreviewed: 0 },
    { name: `Henry`, numUnreviewed: 23 },
  ]),
  recentScreenshots: withIds([
    {
      childName: `Little Jimmy`,
      url: testImgUrl(300, 200),
      createdAt: time.now(),
    },
    {
      childName: `Sally`,
      url: testImgUrl(400, 200),
      createdAt: time.subtracting({ minutes: 2 }),
    },
    {
      childName: `Henry`,
      url: testImgUrl(500, 300),
      createdAt: time.subtracting({ minutes: 6 }),
    },
  ]),
  numParentNotifications: 2,
});

export const NoUnlockRequests: Story = props({
  ...Default.args,
  unlockRequests: [],
});

export const NoChildActivity: Story = props({
  ...Default.args,
  childActivitySummaries: [],
});

// @screenshot: lg
export const NoChildActivityOrUnlockRequests: Story = props({
  ...Default.args,
  childActivitySummaries: [],
  unlockRequests: [],
});

// @screenshot: xs,lg
export const NoChildren: Story = props({
  ...Default.args,
  childData: [],
});

// @screenshot: xs,lg
export const NoDevices: Story = props({
  ...Default.args,
  childData: withIds([{ name: `Little Jimmy`, devices: [] }]),
});

// @screenshot: xs,lg
export const NoNotifications: Story = props({
  ...Default.args,
  numParentNotifications: 0,
});

export const WithPendingIosDevice: Story = props({
  ...Default.args,
  pendingIosDevices: [
    {
      childName: `Little Jimmy`,
      modelName: `iPhone 14`,
      claimCode: 847293,
    },
  ],
});

export const Mixed: Story = props({
  ...Default.args,
  childData: withIds([
    {
      name: `Little Jimmy`,
      devices: [
        {
          platform: `mac`,
          deviceName: `MacBook Pro`,
          macStatus: { case: `filterOn` },
        },
        { platform: `ios`, deviceName: `iPhone 14`, iosStatus: `setupComplete` },
      ],
    },
    {
      name: `Sally`,
      devices: [{ platform: `ios`, deviceName: `iPad Air`, iosStatus: `setupComplete` }],
    },
    {
      name: `Henry`,
      devices: [
        {
          platform: `mac`,
          deviceName: `Mac Mini`,
          macStatus: {
            case: `downtimePaused`,
            resuming: new Date(new Date().getTime() + 5 * 60 * 1000).toISOString(),
          },
        },
        { platform: `mac`, deviceName: `MacBook Pro`, macStatus: { case: `filterOn` } },
        { platform: `ios`, deviceName: `iPhone 15`, iosStatus: `setupComplete` },
      ],
    },
  ]),
  pendingIosDevices: [
    {
      childName: `Sally`,
      modelName: `iPhone 15 Pro`,
      claimCode: 192837,
    },
  ],
});

export const IosOnly: Story = props({
  ...Default.args,
  childData: withIds([
    {
      name: `Little Jimmy`,
      devices: [{ platform: `ios`, deviceName: `iPhone 14`, iosStatus: `setupComplete` }],
    },
    {
      name: `Sally`,
      devices: [
        { platform: `ios`, deviceName: `iPad Air`, iosStatus: `setupComplete` },
        { platform: `ios`, deviceName: `iPhone 15 Pro`, iosStatus: `pendingSetup` },
      ],
    },
    {
      name: `Henry`,
      devices: [{ platform: `ios`, deviceName: `iPhone 13`, iosStatus: `setupComplete` }],
    },
  ]),
  unlockRequests: [],
  childActivitySummaries: [],
  recentScreenshots: [],
});

export default meta;
