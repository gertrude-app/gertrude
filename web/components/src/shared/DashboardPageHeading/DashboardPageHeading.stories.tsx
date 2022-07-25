import { ComponentStory, ComponentMeta } from '@storybook/react';

import DashboardPageHeading from './DashboardPageHeading';

export default {
  title: `DashboardPageHeading`,
  component: DashboardPageHeading,
} as ComponentMeta<typeof DashboardPageHeading>;

const Template: ComponentStory<typeof DashboardPageHeading> = (args) => (
  <DashboardPageHeading {...args} />
);

export const Default = Template.bind({});
Default.args = {
  children: `Profile`,
  icon: `user`,
};
