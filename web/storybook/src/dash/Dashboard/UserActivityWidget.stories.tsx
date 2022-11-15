import { UserActivityWidget } from '@dash/components';
import type { ComponentStory, ComponentMeta } from '@storybook/react';
import { withIds } from '../../story-helpers';

export default {
  title: 'Dashboard/Dashboard/Widgets/UserActivity', // eslint-disable-line
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

// @screenshot: xs/250
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
