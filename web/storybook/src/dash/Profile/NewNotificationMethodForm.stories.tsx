import { NewNotificationMethodForm } from '@dash/components';
import type { StoryFn, ComponentMeta } from '@storybook/react';

export default {
  title: 'Dashboard/Profile/NewNotificationMethodForm', // eslint-disable-line
  component: NewNotificationMethodForm,
} as ComponentMeta<typeof NewNotificationMethodForm>;

const Template: StoryFn<typeof NewNotificationMethodForm> = (args) => (
  <NewNotificationMethodForm {...args} />
);

export const Email = Template.bind({});
Email.args = {
  type: `Email`,
  value: { email: `blob@blob.com` },
  onEvent: () => {},
  sendCodeRequest: { state: `idle` },
  confirmationRequest: { state: `idle` },
  confirmationCode: ``,
};

export const Text = Template.bind({});
Text.args = {
  ...Email.args,
  type: `Text`,
  value: { phoneNumber: `(555) 555-5555` },
};

export const Slack = Template.bind({});
Slack.args = {
  ...Email.args,
  type: `Slack`,
  value: {
    channelName: `gertrude`,
    channelId: `CX0823942d`,
    token: `xoxb-1234567890-1234567890-1234567890`,
  },
};
