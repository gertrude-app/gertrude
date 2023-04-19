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
    { name: `Little Jimmy`, isOnline: true },
    { name: `Sally`, isOnline: true },
    { name: `Henry`, isOnline: false },
  ]),
});

export const NoUsers: Story = props({
  users: [],
});

export default meta;
