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
  devices: [{ id: `1`, icon: `laptop`, model: `14" Macbook Pro`, status: `online` }],
  name: `John Doe`,
  numKeychains: 4,
  numKeys: 57,
  screenshotsEnabled: true,
  keystrokesEnabled: false,
});

export const Empty: Story = props({
  id: ``,
  devices: [],
  name: `John Doe`,
  numKeychains: 0,
  numKeys: 0,
  screenshotsEnabled: false,
  keystrokesEnabled: false,
});

export const Full: Story = props({
  id: ``,
  devices: [
    { id: `1`, icon: `laptop`, model: `13" MacBook Air`, status: `online` },
    { id: `2`, icon: `desktop`, model: `Mac Mini`, status: `offline` },
    { id: `3`, icon: `desktop`, model: `iMac`, status: `offline` },
  ],
  name: `John Doe`,
  numKeychains: 32,
  numKeys: 1546,
  screenshotsEnabled: true,
  keystrokesEnabled: true,
});

export default meta;
