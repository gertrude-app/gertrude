import { ListUsers } from '@dash/components';
import type { StoryFn, ComponentMeta } from '@storybook/react';
import { withStatefulChrome } from '../../decorators/StatefulChrome';

export default {
  title: 'Dashboard/Users/ListUsers', // eslint-disable-line
  component: ListUsers,
  parameters: { layout: `fullscreen` },
  decorators: [withStatefulChrome],
} as ComponentMeta<typeof ListUsers>;

const Template: StoryFn<typeof ListUsers> = (args) => <ListUsers {...args} />;

// @screenshot: xs,md
export const Empty = Template.bind({});
Empty.args = {
  startAddDevice: () => {},
  dismissAddDevice: () => {},
  users: [],
};

// @screenshot: xs,md
export const Default = Template.bind({});
Default.args = {
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
          id: `device-1`,
          icon: `laptop`,
          model: `14" Macbook Pro`,
          status: `online`,
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
          id: `device-2`,
          icon: `laptop`,
          model: `14" Macbook Pro`,
          status: `online`,
        },
        {
          id: `device-3`,
          icon: `desktop`,
          model: `Mac Studio`,
          status: `offline`,
        },
      ],
    },
  ],
};

// @screenshot: xs,md
export const AddingDevice = Template.bind({});
AddingDevice.args = {
  ...Default.args,
  users: Default.args.users!.slice(0, 1),
  addDeviceRequest: {
    state: `succeeded`,
    payload: 123123,
  },
};
