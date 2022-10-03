import { ComponentStory, ComponentMeta } from '@storybook/react';
import UserActivityWidget from './UserActivityWidget';

export default {
  title: `Dashboard/Dashboard/Widgets/UserActivityWidget`,
  component: UserActivityWidget,
} as ComponentMeta<typeof UserActivityWidget>;

const Template: ComponentStory<typeof UserActivityWidget> = (args) => (
  <UserActivityWidget {...args} />
);

export const Default = Template.bind({});
Default.args = {
  userActivity: [
    { user: 'Little Jimmy', unreviewedItems: 245 },
    { user: 'Sally', unreviewedItems: 0 },
    { user: 'Henry', unreviewedItems: 23 },
  ],
};

export const AllCaughtUp = Template.bind({});
AllCaughtUp.args = {
  userActivity: [
    { user: 'Little Jimmy', unreviewedItems: 0 },
    { user: 'Sally', unreviewedItems: 0 },
    { user: 'Henry', unreviewedItems: 0 },
  ],
};

export const NoUsers = Template.bind({});
NoUsers.args = {
  userActivity: [],
};
