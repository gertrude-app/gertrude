import { ComponentStory, ComponentMeta } from '@storybook/react';
import NewNotificationMethodForm from './NewNotificationMethodForm';

export default {
  title: `Dashboard/Profile/NewNotificationMethodForm`,
  component: NewNotificationMethodForm,
} as ComponentMeta<typeof NewNotificationMethodForm>;

const Template: ComponentStory<typeof NewNotificationMethodForm> = (args) => (
  <NewNotificationMethodForm {...args} />
);

export const Email = Template.bind({});
Email.args = {
  type: `email`,
  email: `blob@blob.com`,
  onEvent: () => {},
  sendCodeRequest: { state: `idle` },
  confirmationRequest: { state: `idle` },
  confirmationCode: ``,
};

export const Text = Template.bind({});
Text.args = {
  ...Email.args,
  type: `text`,
  phoneNumber: `(555) 555-5555`,
};

export const Slack = Template.bind({});
Slack.args = {
  ...Email.args,
  type: `slack`,
  channelName: `gertrude`,
  channelId: `CX0823942d`,
  token: `xoxb-1234567890-1234567890-1234567890`,
};
