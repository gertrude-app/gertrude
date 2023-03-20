import { UserActivityOverview } from '@dash/components';
import type { StoryFn, ComponentMeta } from '@storybook/react';
import { withStatefulChrome } from '../../../decorators/StatefulChrome';
import { time } from '../../../story-helpers';

export default {
  title: 'Dashboard/Users/Activity/UserActivityOverview', // eslint-disable-line
  component: UserActivityOverview,
  parameters: { layout: `fullscreen` },
  decorators: [withStatefulChrome],
} as ComponentMeta<typeof UserActivityOverview>;

const Template: StoryFn<typeof UserActivityOverview> = (args) => (
  <UserActivityOverview {...args} />
);

// @screenshot: xs,md
export const Default = Template.bind({});
Default.args = {
  userName: `Huck`,
  days: [
    { date: new Date(time.stable()), numItems: 330, numCompleted: 0 },
    { date: new Date(time.stable()), numItems: 117, numCompleted: 64 },
    { date: new Date(time.stable()), numItems: 89, numCompleted: 89 },
  ],
};

export const Empty = Template.bind({});
Empty.args = {
  ...Default.args,
  days: [],
};
