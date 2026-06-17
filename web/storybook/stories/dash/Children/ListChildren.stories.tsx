import { ListChildren } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { withStatefulChrome } from '../../decorators/StatefulChrome';
import { props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Children/ListChildren', // eslint-disable-line
  component: ListChildren,
  parameters: { layout: `fullscreen` },
  decorators: [withStatefulChrome],
} satisfies Meta<typeof ListChildren>;

type Story = StoryObj<typeof meta>;

// @screenshot: xs,md
export const Empty: Story = props({
  startAddDevice: () => {},
  dismissAddDevice: () => {},
  onStartTrial: () => {},
  users: [],
});

// @screenshot: xs,md
export const Default: Story = props({
  ...Empty.args,
  users: [
    {
      id: `child-4`,
      name: `Lil Suzy`,
      computers: [],
      iosDevices: [],
    },
    {
      id: `child-1`,
      name: `John Doe`,
      computers: [
        {
          id: `1`,
          computerId: `1`,
          customName: `Silvery`,
          modelIdentifier: `Mac14,10`,
          modelTitle: `16" MacBook Pro (2023)`,
          modelFamily: `macBookPro`,
          status: { case: `filterOn` },
        },
      ],
      iosDevices: [],
    },
    {
      id: `child-2`,
      name: `Jane Doe`,
      computers: [
        {
          id: `2`,
          computerId: `2`,
          modelIdentifier: `Mac14,13`,
          customName: `Lil' Studio`,
          modelTitle: `Mac Studio (2023)`,
          modelFamily: `studio`,
          status: { case: `offline` },
        },
        {
          id: `3`,
          computerId: `3`,
          modelIdentifier: `iMac21,2`,
          modelTitle: `27" iMac (2021)`,
          modelFamily: `iMac`,
          status: { case: `filterOn` },
        },
        {
          id: `4`,
          computerId: `3`,
          modelIdentifier: `iMac21,2`,
          modelTitle: `27" iMac (2021)`,
          modelFamily: `iMac`,
          status: {
            case: `filterSuspended`,
            resuming: new Date(new Date().getTime() + 1000 * 60 * 12).toISOString(),
          },
        },
      ],
      iosDevices: [],
    },
  ],
});

export const TrialGate: Story = props({
  ...Default.args,
  users: Default.args.users.slice(0, 1),
  addDeviceRequest: {
    state: `succeeded`,
    payload: { code: 123123, gate: `trialRequired` },
  },
});

export const UpgradeGate: Story = props({
  ...Default.args,
  users: Default.args.users.slice(0, 1),
  addDeviceRequest: {
    state: `succeeded`,
    payload: { code: 123123, gate: `planUpgradeRequired` },
  },
});

export const SubscriptionFixGate: Story = props({
  ...Default.args,
  users: Default.args.users.slice(0, 1),
  addDeviceRequest: {
    state: `succeeded`,
    payload: { code: 123123, gate: `subscriptionFixRequired` },
  },
});

// @screenshot: xs,md
export const AddingDevice: Story = props({
  ...Default.args,
  users: Default.args.users.slice(0, 1),
  addDeviceRequest: {
    state: `succeeded`,
    payload: { code: 123123 },
  },
});

export const WithIosDevices: Story = props({
  ...Empty.args,
  users: [
    {
      id: `child-1`,
      name: `John Doe`,
      computers: [
        {
          id: `1`,
          computerId: `1`,
          customName: `Silvery`,
          modelIdentifier: `Mac14,10`,
          modelTitle: `16" MacBook Pro (2023)`,
          modelFamily: `macBookPro`,
          status: { case: `filterOn` },
        },
      ],
      iosDevices: [
        {
          id: `ios-1`,
          modelName: `iPhone 14`,
          deviceType: `iPhone`,
          iosVersion: `iOS 17.6`,
          pendingClaimCode: 847293,
          musicConnected: false,
        },
      ],
    },
    {
      id: `child-2`,
      name: `Jane Doe`,
      computers: [
        {
          id: `2`,
          computerId: `2`,
          modelIdentifier: `Mac14,13`,
          customName: `Lil' Studio`,
          modelTitle: `Mac Studio (2023)`,
          modelFamily: `studio`,
          status: { case: `offline` },
        },
      ],
      iosDevices: [
        {
          id: `ios-2`,
          modelName: `iPhone 15 Pro`,
          deviceType: `iPhone`,
          iosVersion: `iOS 18.2`,
          musicConnected: true,
        },
      ],
    },
  ],
});

export default meta;
