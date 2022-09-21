import { ComponentStory, ComponentMeta } from '@storybook/react';
import UsersOverview from './UsersOverviewWidget';

export default {
  title: `Dashboard/Dashboard/Widgets/UserOverviewWidget`,
  component: UsersOverview,
} as ComponentMeta<typeof UsersOverview>;

const Template: ComponentStory<typeof UsersOverview> = (args) => (
  <UsersOverview {...args} />
);

export const Default = Template.bind({});
Default.args = {
  users: [
    { name: 'Little Jimmy', online: true },
    { name: 'Sally', online: true },
    { name: 'Henry', online: false },
  ],
};

export const NoUsers = Template.bind({});
NoUsers.args = {
  users: [],
};
