import { DaySummaryCard } from '@dash/components';
import type { ComponentStory, ComponentMeta } from '@storybook/react';
import { time } from '../../../story-helpers';

export default {
  title: 'Dashboard/Users/Activity/DaySummaryCard', // eslint-disable-line
  component: DaySummaryCard,
} as ComponentMeta<typeof DaySummaryCard>;

const Template: ComponentStory<typeof DaySummaryCard> = (args) => (
  <DaySummaryCard {...args} />
);

export const Default = Template.bind({});
Default.args = {
  date: new Date(time.stable()),
  numItems: 36,
  numCompleted: 24,
};

export const Empty = Template.bind({});
Empty.args = {
  ...Default.args,
  numItems: 77,
  numCompleted: 0,
};

export const Completed = Template.bind({});
Completed.args = {
  ...Default.args,
  numItems: 77,
  numCompleted: 77,
};
