import { ComponentStory, ComponentMeta } from '@storybook/react';

import EmailFormScreen from './EmailFormScreen';

export default {
  title: `EmailFormScreen`,
  component: EmailFormScreen,
  parameters: {
    layout: `fullscreen`,
  },
} as ComponentMeta<typeof EmailFormScreen>;

const Template: ComponentStory<typeof EmailFormScreen> = (args) => (
  <EmailFormScreen {...args} />
);

export const Default = Template.bind({});
Default.args = {
  state: `default`,
  title: `Join the waitlist`,
  subTitle: `We'll notify you when you can begin trying out Gertrude`,
};

export const Fetching = Template.bind({});
Fetching.args = { state: `fetching` };

export const Success = Template.bind({});
Success.args = {
  state: `success`,
  message: `Success! Check your email for a verification link.`,
};

export const Error = Template.bind({});
Error.args = {
  state: `error`,
  error: `Something went wrong. Please try again.`,
};
