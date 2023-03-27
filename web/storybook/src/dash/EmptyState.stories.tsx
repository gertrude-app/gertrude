import { EmptyState } from '@dash/components';
import type { StoryFn, ComponentMeta } from '@storybook/react';

export default {
  title: 'Dashboard/Core/EmptyState', // eslint-disable-line
  component: EmptyState,
} as ComponentMeta<typeof EmptyState>;

const Template: StoryFn<typeof EmptyState> = (args) => <EmptyState {...args} />;

// @screenshot: xs/350,md/350
export const Default = Template.bind({});
Default.args = {
  heading: `No burgers`,
  secondaryText: `Let's make some!`,
  buttonText: `Make a burger`,
  icon: `burger`,
};

// @screenshot: xs/350,md/350
export const WithSecondaryButton = Template.bind({});
WithSecondaryButton.args = {
  heading: `No burgers`,
  secondaryText: `Let's make some!`,
  buttonText: `Make a burger`,
  icon: `burger`,
  secondaryButton: {
    text: `Or not`,
    action: () => {},
    icon: `times`,
  },
};

// @screenshot: xs/350
export const Violet = Template.bind({});
Violet.args = {
  ...Default.args,
  violet: true,
};
