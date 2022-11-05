import { NotificationMethod } from '@dash/components';
import type { ComponentStory, ComponentMeta } from '@storybook/react';

export default {
  title: `Dashboard/Profile/NotificationMethod`,
  component: NotificationMethod,
} as ComponentMeta<typeof NotificationMethod>;

const Template: ComponentStory<typeof NotificationMethod> = (args) => (
  <NotificationMethod {...args} />
);

export const Email = Template.bind({});
Email.args = {
  method: `email`,
  value: `me@example.com`,
};

export const Text = Template.bind({});
Text.args = {
  method: `text`,
  value: `+1 (555) 555-5555`,
};

export const Slack = Template.bind({});
Slack.args = {
  method: `slack`,
  value: `#Gertrude`,
};
