import { ComponentStory, ComponentMeta } from '@storybook/react';
import FullscreenModalForm from '../FullscreenModalForm';
import LoginForm from './LoginForm';

export default {
  title: `Dashboard/Unauthed/LoginForm`,
  component: LoginForm,
  parameters: { layout: `fullscreen` },
} as ComponentMeta<typeof LoginForm>;

const Template: ComponentStory<typeof LoginForm> = (args) => (
  <FullscreenModalForm request="idle">
    <LoginForm {...args} />
  </FullscreenModalForm>
);

export const Default = Template.bind({});
Default.args = {
  email: ``,
  setEmail: () => {},
  password: ``,
  setPassword: () => {},
  onSubmit: () => {},
  onSendMagicLink: () => {},
};
