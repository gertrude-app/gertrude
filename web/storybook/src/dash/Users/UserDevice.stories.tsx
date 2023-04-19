import { UserDevice } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Users/UserDevice', // eslint-disable-line
  component: UserDevice,
} satisfies Meta<typeof UserDevice>;

type Story = StoryObj<typeof meta>;

export const Online: Story = props({
  model: `14" Macbook Pro`,
  icon: `laptop`,
  status: `online`,
});

export const Offline: Story = props({
  ...Online.args,
  status: `offline`,
});

export default meta;
