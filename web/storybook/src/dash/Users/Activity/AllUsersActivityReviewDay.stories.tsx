import { AllUsersActivityReviewDay } from '@dash/components';
import type { ComponentStory, ComponentMeta } from '@storybook/react';
import { withStatefulChrome } from '../../../decorators/StatefulChrome';
import { activity, time } from '../../../story-helpers';

export default {
  title: 'Dashboard/Users/Activity/AllUsersActivityReviewDay', // eslint-disable-line
  component: AllUsersActivityReviewDay,
  parameters: { layout: `fullscreen` },
  decorators: [withStatefulChrome],
} as ComponentMeta<typeof AllUsersActivityReviewDay>;

const Template: ComponentStory<typeof AllUsersActivityReviewDay> = (args) => (
  <AllUsersActivityReviewDay {...args} />
);

// @screenshot: xs,md
export const Default = Template.bind({});
Default.args = {
  date: new Date(time.stable()),
  chunkSize: 3,
  activity: activity,
  numDeleted: 0,
  deleteItems: () => {},
};

export const Empty = Template.bind({});
Empty.args = { ...Default.args, activity: {} };
