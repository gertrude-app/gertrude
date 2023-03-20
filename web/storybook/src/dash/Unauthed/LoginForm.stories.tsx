import { FullscreenModalForm, LoginForm } from '@dash/components';
import type { StoryFn, ComponentMeta } from '@storybook/react';

export default {
  title: 'Dashboard/Unauthed/LoginForm', // eslint-disable-line
  component: LoginForm,
  parameters: { layout: `fullscreen` },
} as ComponentMeta<typeof LoginForm>;

const Template: StoryFn<typeof LoginForm> = (args) => (
  <FullscreenModalForm request="idle">
    <LoginForm {...args} />
  </FullscreenModalForm>
);

// @screenshot: xs,md
export const Default = Template.bind({});
Default.args = {
  email: ``,
  setEmail: () => {},
  password: ``,
  setPassword: () => {},
  onSubmit: () => {},
  onSendMagicLink: () => {},
};
