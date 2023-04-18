import { ReviewDayHeader } from '@dash/components';
import type { ComponentStory, ComponentMeta } from '@storybook/react';
import { time } from '../../../story-helpers';

export default {
  title: 'Dashboard/Users/Activity/ReviewDayHeader', // eslint-disable-line
  component: ReviewDayHeader,
} as ComponentMeta<typeof ReviewDayHeader>;

const Template: ComponentStory<typeof ReviewDayHeader> = (args) => (
  <ReviewDayHeader {...args} />
);

export const Default = Template.bind({});
Default.args = {
  date: new Date(time.stable()),
  numItems: 63,
  numDeleted: 0,
};

export const Empty = Template.bind({});
Empty.args = {
  ...Default.args,
  numItems: 0,
  numDeleted: 0,
};

export const Completed = Template.bind({});
Completed.args = {
  ...Default.args,
  numItems: 6,
  numDeleted: 6,
};
