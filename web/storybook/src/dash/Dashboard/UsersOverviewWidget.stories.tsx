import { UsersOverviewWidget } from '@dash/components';
import type { StoryFn, ComponentMeta } from '@storybook/react';
import { withIds } from '../../story-helpers';

export default {
  title: 'Dashboard/Dashboard/Widgets/UserOverview', // eslint-disable-line
  component: UsersOverviewWidget,
} as ComponentMeta<typeof UsersOverviewWidget>;

const Template: StoryFn<typeof UsersOverviewWidget> = (args) => (
  <UsersOverviewWidget {...args} />
);

export const Default = Template.bind({});
Default.args = {
  users: withIds([
    { name: `Little Jimmy`, isOnline: true },
    { name: `Sally`, isOnline: true },
    { name: `Henry`, isOnline: false },
  ]),
};

export const NoUsers = Template.bind({});
NoUsers.args = {
  users: [],
};
