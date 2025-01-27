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
    { name: `Little Jimmy`, status: { case: `filterOn` }, numDevices: 1 },
    { name: `Sally`, status: { case: `filterOn` }, numDevices: 2 },
    { name: `Henry`, status: { case: `offline` }, numDevices: 0 },
  ]),
});

export const NoUsers: Story = props({
  users: [],
});

export default meta;
