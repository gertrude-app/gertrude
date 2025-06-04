import { UserDevice } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Users/UserDevice', // eslint-disable-line
  component: UserDevice,
} satisfies Meta<typeof UserDevice>;

type Story = StoryObj<typeof meta>;

export const Online: Story = props({
  id: `123`,
  deviceId: `d1`,
  modelTitle: `15" Macbook Pro (2023)`,
  modelIdentifier: `Mac14,10`,
  icon: `laptop`,
  status: { case: `filterOn` },
  name: `Silvery`,
});

export const Offline: Story = props({
  ...Online.args,
  status: { case: `offline` },
});

export const Suspended: Story = props({
  ...Online.args,
  status: {
    case: `filterSuspended`,
    resuming: new Date(new Date().getTime() + 7 * 60 * 1000).toISOString(),
  },
});

export const Downtime: Story = props({
  ...Online.args,
  status: {
    case: `downtime`,
    ending: new Date(new Date().getTime() + 60 * 60 * 1000).toISOString(),
  },
});

export const DowntimePaused: Story = props({
  ...Online.args,
  status: {
    case: `downtimePaused`,
    resuming: new Date(new Date().getTime() + 5 * 60 * 1000).toISOString(),
  },
});

export const FilterOff: Story = props({
  ...Online.args,
  status: { case: `filterOff` },
});

export const NoName: Story = props({
  ...Online.args,
  name: undefined,
});

export default meta;
