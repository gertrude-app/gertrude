import { ComponentStory, ComponentMeta } from '@storybook/react';

import NotificationMethod from './NotificationMethod';

export default {
  title: `NotificationMethod`,
  component: NotificationMethod,
} as ComponentMeta<typeof NotificationMethod>;

const Template: ComponentStory<typeof NotificationMethod> = (args) => (
  <NotificationMethod {...args} />
);

export const Email = Template.bind({});
Email.args = {
  method: `email`,
  address: `me@example.com`,
};

export const Text = Template.bind({});
Text.args = {
  method: `text`,
  number: `+1 (555) 555-5555`,
};

export const Slack = Template.bind({});
Slack.args = {
  method: `slack`,
  channel: `#Gertrude`,
};
