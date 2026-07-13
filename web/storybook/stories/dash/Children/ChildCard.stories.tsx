import { ChildCard } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Children/ChildCard',
  component: ChildCard,
} satisfies Meta<typeof ChildCard>;

type Story = StoryObj<typeof meta>;

export const Standard: Story = props({
  id: ``,
  computers: [
    {
      id: `1`,
      computerId: `1`,
      modelTitle: `16" Macbook Pro (2023)`,
      modelIdentifier: `Mac14,10`,
      modelFamily: `macBookPro`,
      status: { case: `filterOn` },
    },
  ],
  iosDevices: [],
  name: `John Doe`,
  addDevice: () => {},
});

export const Empty: Story = props({
  id: ``,
  computers: [],
  iosDevices: [],
  name: `John Doe`,
  addDevice: () => {},
});

export const Full: Story = props({
  id: ``,
  computers: [
    {
      id: `1`,
      computerId: `1`,
      modelIdentifier: `Mac14,10`,
      modelTitle: `16" MacBook Pro (2023)`,
      modelFamily: `macBookPro`,
      status: { case: `offline` },
    },
    {
      id: `2`,
      computerId: `2`,
      modelIdentifier: `Mac14,13`,
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
  ],
  iosDevices: [],
  name: `John Doe`,
  addDevice: () => {},
});

export default meta;
