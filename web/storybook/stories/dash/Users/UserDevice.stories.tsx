import { UserDevice } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
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
  status: `online`,
  name: `Silvery`,
});

export const Offline: Story = props({
  ...Online.args,
  status: `offline`,
});

export const NoName: Story = props({
  ...Online.args,
  name: undefined,
});

export default meta;
