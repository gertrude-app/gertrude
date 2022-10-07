import { ComponentStory, ComponentMeta } from '@storybook/react';
import UsersOverview from './UsersOverviewWidget';
import { withIds } from '../../../story-helpers';

export default {
  title: `Dashboard/Dashboard/Widgets/UserOverview`,
  component: UsersOverview,
} as ComponentMeta<typeof UsersOverview>;

const Template: ComponentStory<typeof UsersOverview> = (args) => (
  <UsersOverview {...args} />
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
