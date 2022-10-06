import { ComponentStory, ComponentMeta } from '@storybook/react';
import UserActivityWidget from './UserActivityWidget';
import { withIds } from '../../../story-helpers';

export default {
  title: `Dashboard/Dashboard/Widgets/UserActivity`,
  component: UserActivityWidget,
} as ComponentMeta<typeof UserActivityWidget>;

const Template: ComponentStory<typeof UserActivityWidget> = (args) => (
  <UserActivityWidget {...args} />
);

export const Default = Template.bind({});
Default.args = {
  userActivity: withIds([
    { userName: `Little Jimmy`, numUnreviewed: 245 },
    { userName: `Sally`, numUnreviewed: 0 },
    { userName: `Henry`, numUnreviewed: 23 },
  ]),
};

export const AllCaughtUp = Template.bind({});
AllCaughtUp.args = {
  userActivity: withIds([
    { userName: `Little Jimmy`, numUnreviewed: 0 },
    { userName: `Sally`, numUnreviewed: 0 },
    { userName: `Henry`, numUnreviewed: 0 },
  ]),
};

export const NoUsers = Template.bind({});
NoUsers.args = {
  userActivity: [],
};
