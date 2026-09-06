import { ListDevices } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { withStatefulChrome } from '../../decorators/StatefulChrome';
import { props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Devices/ListDevices',
  component: ListDevices,
  parameters: { layout: `fullscreen` },
  decorators: [withStatefulChrome],
} satisfies Meta<typeof ListDevices>;

type Story = StoryObj<typeof meta>;

export const Empty: Story = props({
  computers: [],
  iosDevices: [],
});

export const MacOnly: Story = props({
  computers: [
    {
      id: `device-1`,
      name: `Silvery`,
      modelIdentifier: `Mac14,10`,
      modelTitle: `16" MacBook Pro (2023)`,
      users: [
        {
          computerUserId: `computer-user-1`,
          name: `Franny`,
          status: { case: `filterOn` },
          id: `child-1`,
        },
      ],
    },
    {
      id: `device-2`,
      modelIdentifier: `Mac14,15`,
      modelTitle: `15" MacBook Air (2023)`,
      users: [
        {
          computerUserId: `computer-user-2`,
          name: `Zooey`,
          status: {
            case: `filterSuspended`,
            resuming: new Date(new Date().getTime() + 7 * 60 * 1000).toISOString(),
          },
          id: `child-2`,
        },
      ],
    },
    {
      id: `device-3`,
      name: `Family iMac`,
      modelIdentifier: `iMac21,2`,
      modelTitle: `27" iMac (2021)`,
      users: [
        {
          computerUserId: `computer-user-3`,
          name: `Franny`,
          status: { case: `offline` },
          id: `child-1`,
        },
        {
          computerUserId: `computer-user-4`,
          name: `Zooey`,
          status: { case: `filterOn` },
          id: `child-2`,
        },
      ],
    },
  ],
  iosDevices: [],
});

export const IOSOnly: Story = props({
  computers: [],
  iosDevices: [
    {
      id: `ios-1`,
      childId: `child-1`,
      childName: `Franny`,
      modelName: `iPhone 15 Pro`,
      deviceType: `iPhone`,
      iosVersion: `iOS 18.2`,
    },
    {
      id: `ios-2`,
      childId: `child-2`,
      childName: `Zooey`,
      modelName: `iPhone 14`,
      deviceType: `iPhone`,
      iosVersion: `iOS 17.6`,
    },
    {
      id: `ios-3`,
      childId: `child-2`,
      childName: `Zooey`,
      modelName: `iPad Air`,
      deviceType: `iPad`,
      iosVersion: `iPadOS 17.6`,
      pendingSetup: true,
    },
  ],
});

// @screenshot: xs,md
export const Mixed: Story = props({
  computers: [
    {
      id: `device-1`,
      name: `Silvery`,
      modelIdentifier: `Mac14,10`,
      modelTitle: `16" MacBook Pro (2023)`,
      users: [
        {
          computerUserId: `computer-user-5`,
          name: `Franny`,
          status: { case: `filterOn` },
          id: `child-1`,
        },
      ],
    },
    {
      id: `device-2`,
      name: `Family iMac`,
      modelIdentifier: `iMac21,2`,
      modelTitle: `27" iMac (2021)`,
      users: [
        {
          computerUserId: `computer-user-6`,
          name: `Franny`,
          status: { case: `offline` },
          id: `child-1`,
        },
        {
          computerUserId: `computer-user-7`,
          name: `Zooey`,
          status: { case: `filterOn` },
          id: `child-2`,
        },
      ],
    },
  ],
  iosDevices: [
    {
      id: `ios-1`,
      childId: `child-1`,
      childName: `Franny`,
      modelName: `iPhone 15 Pro`,
      deviceType: `iPhone`,
      iosVersion: `iOS 18.2`,
    },
    {
      id: `ios-2`,
      childId: `child-2`,
      childName: `Zooey`,
      modelName: `iPad Air`,
      deviceType: `iPad`,
      iosVersion: `iPadOS 17.6`,
      pendingSetup: true,
    },
  ],
});

export default meta;
