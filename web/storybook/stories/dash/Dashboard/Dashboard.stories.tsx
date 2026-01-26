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
  childData: withIds([
    { name: `Little Jimmy`, status: { case: `filterOn` }, numDevices: 0 },
  ]),
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

export const WithPendingIosDeviceAndAnnouncement: Story = props({
  ...Default.args,
  pendingIosDevices: [
    {
      childName: `Little Jimmy`,
      modelName: `iPhone 14`,
      claimCode: 847293,
    },
  ],
  announcement: {
    id: `e60c0317-2af6-409a-bc6b-ee7c0d724d27`,
    kind: `warning`,
    icon: `fa-solid fa-triangle-exclamation`,
    html: `<b>Action needed:</b> We detected that Screen Time web filtering is enabled on <b>Yeshua\u2019s</b> mac computer, which can interfere with Gertrude\u2019s ability to protect your child. Disable Screen Time\u2019s \u201cRestrictions\u201d &rarr; \u201cContent &amp; Privacy\u201d section to fix.`,
    learnMoreUrl: `https://gertrude.app/blog/screen-time-web-filter-conflict`,
  },
});

export const WithMultiplePendingIosDevices: Story = props({
  ...Default.args,
  pendingIosDevices: [
    {
      childName: `Little Jimmy`,
      modelName: `iPhone 14`,
      claimCode: 847293,
    },
    {
      childName: `Sally`,
      modelName: `iPhone 15 Pro`,
      claimCode: 192837,
    },
  ],
});

export default meta;
