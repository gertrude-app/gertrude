import { ComponentStory, ComponentMeta } from '@storybook/react';
import { EmailInputForm, FullscreenModalForm } from '@dash/components';

export default {
  title: `Dashboard/Unauthed/FullscreenModalForm`,
  component: FullscreenModalForm,
  parameters: {
    layout: `fullscreen`,
  },
} as ComponentMeta<typeof FullscreenModalForm>;

const Template: ComponentStory<typeof FullscreenModalForm> = (args) => (
  <FullscreenModalForm {...args} />
);

export const Default = Template.bind({});
Default.args = {
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
};

export const Fetching = Template.bind({});
Fetching.args = { request: `ongoing` };

export const Succeeded = Template.bind({});
Succeeded.args = {
  request: `succeeded`,
  message: `Success! Check your email for a verification link.`,
};

export const Failed = Template.bind({});
Failed.args = {
  request: `failed`,
  error: `Something went wrong. Please try again.`,
};
