import { Trigger } from '@dash/types';
import { NotificationCard } from '@dash/components';
import type { ComponentStory, ComponentMeta } from '@storybook/react';

export default {
  title: 'Dashboard/Profile/NotificationCard', // eslint-disable-line
  component: NotificationCard,
} as ComponentMeta<typeof NotificationCard>;

const Template: ComponentStory<typeof NotificationCard> = (args) => (
  <NotificationCard {...args} />
);

export const Email = Template.bind({});
Email.args = {
  selectedMethod: { id: `1`, data: { type: `email`, email: `me@example.com` } },
  trigger: Trigger.unlockRequestSubmitted,
  editing: false,
  onDelete: () => {},
  startEdit: () => {},
  cancelEdit: () => {},
  updateMethod: () => {},
  updateTrigger: () => {},
  methodOptions: [
    { display: `Email foo@bar.com`, value: `1` },
    { display: `Text (555) 555-5555`, value: `2` },
    { display: `Slack #Gertrude`, value: `3` },
  ],
};

export const Text = Template.bind({});
Text.args = {
  ...Email.args,
  selectedMethod: { id: `2`, data: { type: `text`, phoneNumber: `(123) 456-7890` } },
  trigger: Trigger.unlockRequestSubmitted,
};

export const Slack = Template.bind({});
Slack.args = {
  ...Email.args,
  selectedMethod: {
    id: `3`,
    data: { type: `slack`, channelId: ``, channelName: `#Gertrude`, token: `` },
  },
  trigger: Trigger.suspendFilterRequestSubmitted,
};
