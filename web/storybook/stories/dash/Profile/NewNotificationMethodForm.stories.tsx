import { NewNotificationMethodForm } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { fixedViewport, props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Settings/NewNotificationMethodForm', // eslint-disable-line
  component: NewNotificationMethodForm,
  parameters: fixedViewport(385, 812),
} satisfies Meta<typeof NewNotificationMethodForm>;

type Story = StoryObj<typeof meta>;

export const Email: Story = props({
  case: `email`,
  email: `blob@blob.com`,
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
