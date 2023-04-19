import { NewNotificationMethodForm } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Profile/NewNotificationMethodForm', // eslint-disable-line
  component: NewNotificationMethodForm,
} satisfies Meta<typeof NewNotificationMethodForm>;

type Story = StoryObj<typeof meta>;

export const Email: Story = props({
  type: `Email`,
  value: { email: `blob@blob.com` },
  onEvent: () => {},
  sendCodeRequest: { state: `idle` },
  confirmationRequest: { state: `idle` },
  confirmationCode: ``,
});

export const Text: Story = props({
  ...Email.args,
  type: `Text`,
  value: { phoneNumber: `(555) 555-5555` },
});

export const Slack: Story = props({
  ...Email.args,
  type: `Slack`,
  value: {
    channelName: `gertrude`,
    channelId: `CX0823942d`,
    token: `xoxb-1234567890-1234567890-1234567890`,
  },
});

export default meta;
