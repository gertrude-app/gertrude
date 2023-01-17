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
  selectedMethod: {
    type: `VerifiedEmailMethod`,
    value: { id: `1`, email: `me@example.com` },
  },
  trigger: `unlockRequestSubmitted`,
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
  selectedMethod: {
    type: `VerifiedTextMethod`,
    value: { id: `2`, phoneNumber: `(123) 456-7890` },
  },
  trigger: `unlockRequestSubmitted`,
};

export const Slack = Template.bind({});
Slack.args = {
  ...Email.args,
  selectedMethod: {
    type: `VerifiedSlackMethod`,
    value: {
      id: `3`,
      channelId: ``,
      channelName: `#Gertrude`,
      token: ``,
    },
  },
  trigger: `suspendFilterRequestSubmitted`,
};
