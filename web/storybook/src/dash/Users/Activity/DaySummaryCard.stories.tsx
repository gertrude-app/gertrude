import { ComponentStory, ComponentMeta } from '@storybook/react';
import { DaySummaryCard } from '@dash/components';

export default {
  title: `Dashboard/Users/Activity/DaySummaryCard`,
  component: DaySummaryCard,
} as ComponentMeta<typeof DaySummaryCard>;

const Template: ComponentStory<typeof DaySummaryCard> = (args) => (
  <DaySummaryCard {...args} />
);

export const Default = Template.bind({});
Default.args = { date: new Date(), numItems: 36, numCompleted: 24 };

export const Empty = Template.bind({});
Empty.args = { date: new Date(), numItems: 77, numCompleted: 0 };

export const Completed = Template.bind({});
Completed.args = { date: new Date(), numItems: 77, numCompleted: 77 };
