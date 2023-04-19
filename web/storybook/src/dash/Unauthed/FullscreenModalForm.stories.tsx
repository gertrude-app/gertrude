import { EmailInputForm, FullscreenModalForm } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Unauthed/FullscreenModalForm', // eslint-disable-line
  component: FullscreenModalForm,
  parameters: {
    layout: `fullscreen`,
  },
} satisfies Meta<typeof FullscreenModalForm>;

type Story = StoryObj<typeof meta>;

export const Default: Story = props({
  request: `idle`,
  children: (
    <EmailInputForm
      title="Join the waitlist"
      subTitle="We'll notify you when you can begin trying out Gertrude"
      email=""
      setEmail={() => {}}
      onSubmit={() => {}}
    />
  ),
});

export const Fetching: Story = props({
  request: `ongoing`,
});

// @screenshot: xs,md
export const Succeeded: Story = props({
  request: `succeeded`,
  message: `Success! Check your email for a verification link.`,
});

// @screenshot: xs,md
export const Failed: Story = props({
  request: `failed`,
  error: `Something went wrong. Please try again.`,
});

export default meta;
