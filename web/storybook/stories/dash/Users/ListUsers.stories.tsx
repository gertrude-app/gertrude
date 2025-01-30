import { ListUsers } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { withStatefulChrome } from '../../decorators/StatefulChrome';
import { props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Users/ListUsers', // eslint-disable-line
  component: ListUsers,
  parameters: { layout: `fullscreen` },
  decorators: [withStatefulChrome],
} satisfies Meta<typeof ListUsers>;

type Story = StoryObj<typeof meta>;

// @screenshot: xs,md
export const Empty: Story = props({
  startAddDevice: () => {},
  dismissAddDevice: () => {},
  users: [],
});

// @screenshot: xs,md
export const Default: Story = props({
  ...Empty.args,
  users: [
    {
      id: `user-4`,
      name: `Lil Suzy`,
      numKeys: 33,
      numKeychains: 55,
      screenshotsEnabled: true,
      keystrokesEnabled: true,
      devices: [],
    },
    {
      id: `user-1`,
      name: `John Doe`,
      numKeys: 33,
      numKeychains: 55,
      screenshotsEnabled: true,
      keystrokesEnabled: true,
      devices: [
        {
          id: `1`,
          deviceId: `1`,
          name: `Silvery`,
          modelIdentifier: `Mac14,10`,
          modelTitle: `16" MacBook Pro (2023)`,
          status: { case: `filterOn` },
        },
      ],
    },
    {
      id: `user-2`,
      name: `Jane Doe`,
      numKeys: 55,
      numKeychains: 2,
      screenshotsEnabled: false,
      keystrokesEnabled: false,
      devices: [
        {
          id: `2`,
          deviceId: `2`,
          modelIdentifier: `Mac14,13`,
          name: `Lil' Studio`,
          modelTitle: `Mac Studio (2023)`,
          status: { case: `offline` },
        },
        {
          id: `3`,
          deviceId: `3`,
          modelIdentifier: `iMac21,2`,
          modelTitle: `27" iMac (2021)`,
          status: { case: `filterOn` },
        },
      ],
    },
  ],
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

export default meta;
