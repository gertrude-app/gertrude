import { NotificationCard } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Profile/NotificationCard', // eslint-disable-line
  component: NotificationCard,
} satisfies Meta<typeof NotificationCard>;

type Story = StoryObj<typeof meta>;

export const Email: Story = props({
  selectedMethod: {
    type: `VerifiedEmailMethod`,
    value: { id: `1`, email: `me@example.com` },
  },
  trigger: `unlockRequestSubmitted`,
  saveButtonDisabled: false,
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
});

export const Text: Story = props({
  ...Email.args,
  selectedMethod: {
    type: `VerifiedTextMethod`,
    value: { id: `2`, phoneNumber: `(123) 456-7890` },
  },
  trigger: `unlockRequestSubmitted`,
});

export const Slack: Story = props({
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
});

export default meta;
