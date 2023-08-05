import { FullscreenModalForm, LoginForm } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Unauthed/LoginForm', // eslint-disable-line
  component: LoginForm,
  parameters: { layout: `fullscreen` },
  decorators: [
    (Story) => (
      <FullscreenModalForm state="idle">
        <Story />
      </FullscreenModalForm>
    ),
  ],
} satisfies Meta<typeof LoginForm>;

type Story = StoryObj<typeof meta>;

// @screenshot: xs,md
export const Default: Story = props({
  email: ``,
  setEmail: () => {},
  password: ``,
  setPassword: () => {},
  onSubmit: () => {},
  onSendMagicLink: () => {},
});

export default meta;
