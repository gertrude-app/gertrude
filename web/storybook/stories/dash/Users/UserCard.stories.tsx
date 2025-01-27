import { UserCard } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Users/UserCard', // eslint-disable-line
  component: UserCard,
} satisfies Meta<typeof UserCard>;

type Story = StoryObj<typeof meta>;

export const Standard: Story = props({
  id: ``,
  devices: [
    {
      id: `1`,
      deviceId: `1`,
      modelTitle: `16" Macbook Pro (2023)`,
      modelIdentifier: `Mac14,10`,
      status: { case: `filterOn` },
    },
  ],
  name: `John Doe`,
  numKeychains: 4,
  numKeys: 57,
  screenshotsEnabled: true,
  keystrokesEnabled: false,
  addDevice: () => {},
});

export const Empty: Story = props({
  id: ``,
  devices: [],
  name: `John Doe`,
  numKeychains: 0,
  numKeys: 0,
  screenshotsEnabled: false,
  keystrokesEnabled: false,
  addDevice: () => {},
});

export const Full: Story = props({
  id: ``,
  devices: [
    {
      id: `1`,
      deviceId: `1`,
      modelIdentifier: `Mac14,10`,
      modelTitle: `16" MacBook Pro (2023)`,
      status: { case: `offline` },
    },
    {
      id: `2`,
      deviceId: `2`,
      modelIdentifier: `Mac14,13`,
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
  name: `John Doe`,
  numKeychains: 32,
  numKeys: 1546,
  screenshotsEnabled: true,
  keystrokesEnabled: true,
  addDevice: () => {},
});

export default meta;
