import { UsersOverviewWidget } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { withIds, props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Dashboard/Widgets/UserOverview', // eslint-disable-line
  component: UsersOverviewWidget,
} satisfies Meta<typeof UsersOverviewWidget>;

type Story = StoryObj<typeof meta>;

export const Default: Story = props({
  users: withIds([
    { name: `Little Jimmy`, isOnline: true, numDevices: 1 },
    { name: `Sally`, isOnline: true, numDevices: 2 },
    { name: `Henry`, isOnline: false, numDevices: 0 },
  ]),
});

export const NoUsers: Story = props({
  users: [],
});

export default meta;
