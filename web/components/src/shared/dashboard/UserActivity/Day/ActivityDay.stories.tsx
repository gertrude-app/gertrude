import { ComponentStory, ComponentMeta } from '@storybook/react';

import ActivityDay from './ActivityDay';

export default {
  title: `Dashboard/UserActivity/ActivityDay`,
  component: ActivityDay,
} as ComponentMeta<typeof ActivityDay>;

const Template: ComponentStory<typeof ActivityDay> = (args) => <ActivityDay {...args} />;

export const Default = Template.bind({});
Default.args = { date: new Date(), numItems: 36, numCompleted: 24, to: `/` };
