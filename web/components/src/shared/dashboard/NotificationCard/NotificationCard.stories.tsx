import { ComponentStory, ComponentMeta } from '@storybook/react';

import NotificationCard from './NotificationCard';

export default {
  title: `NotificationCard`,
  component: NotificationCard,
} as ComponentMeta<typeof NotificationCard>;

const Template: ComponentStory<typeof NotificationCard> = (args) => (
  <NotificationCard {...args} />
);

export const Email = Template.bind({});
Email.args = {
  method: `email`,
  email: `me@example.com`,
  when: `suspension requests`,
};

export const Text = Template.bind({});
Text.args = {
  method: `text`,
  number: `(123) 456-7890`,
  when: `suspension requests`,
};

export const Slack = Template.bind({});
Slack.args = {
  method: `slack`,
  channelName: `#Gertrude`,
  when: `unlock requests`,
};
