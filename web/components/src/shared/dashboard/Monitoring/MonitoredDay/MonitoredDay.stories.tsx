import { ComponentStory, ComponentMeta } from '@storybook/react';

import MonitoredDay from './MonitoredDay';

export default {
  title: `Dashboard/Monitoring/MonitoredDay`,
  component: MonitoredDay,
} as ComponentMeta<typeof MonitoredDay>;

const Template: ComponentStory<typeof MonitoredDay> = (args) => (
  <MonitoredDay {...args} />
);

export const Default = Template.bind({});
Default.args = { date: new Date(), numItems: 36, numCompleted: 24, to: `/` };
