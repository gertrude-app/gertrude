import { EmptyState } from '@dash/components';
import type { ComponentStory, ComponentMeta } from '@storybook/react';

export default {
  title: `Dashboard/Core/EmptyState`,
  component: EmptyState,
} as ComponentMeta<typeof EmptyState>;

const Template: ComponentStory<typeof EmptyState> = (args) => <EmptyState {...args} />;

export const Default = Template.bind({});
Default.args = {
  heading: `No burgers`,
  secondaryText: `Let's make some!`,
  buttonText: `Make a burger`,
  icon: `burger`,
};

export const Violet = Template.bind({});
Violet.args = {
  ...Default.args,
  violet: true,
};
