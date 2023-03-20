import { UserActivityWidget } from '@dash/components';
import type { StoryFn, ComponentMeta } from '@storybook/react';
import { withIdsAnd } from '../../story-helpers';

export default {
  title: 'Dashboard/Dashboard/Widgets/UserActivity', // eslint-disable-line
  component: UserActivityWidget,
} as ComponentMeta<typeof UserActivityWidget>;

const Template: StoryFn<typeof UserActivityWidget> = (args) => (
  <UserActivityWidget {...args} />
);

export const Default = Template.bind({});
Default.args = {
  userActivity: withIdsAnd({ numReviewed: 0 }, [
    { name: `Little Jimmy`, numUnreviewed: 245 },
    { name: `Sally`, numUnreviewed: 0 },
    { name: `Henry`, numUnreviewed: 23 },
  ]),
};

// @screenshot: xs/250
export const AllCaughtUp = Template.bind({});
AllCaughtUp.args = {
  userActivity: withIdsAnd({ numReviewed: 0 }, [
    { name: `Little Jimmy`, numUnreviewed: 0 },
    { name: `Sally`, numUnreviewed: 0 },
    { name: `Henry`, numUnreviewed: 0 },
  ]),
};

export const NoUsers = Template.bind({});
NoUsers.args = {
  userActivity: [],
};
