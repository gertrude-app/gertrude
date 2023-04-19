import { Profile } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { withStatefulChrome } from '../../decorators/StatefulChrome';
import { withIdsAnd, confirmableEntityAction, props } from '../../story-helpers';
import { Email as CardStory } from './NotificationCard.stories';

const meta = {
  title: 'Dashboard/Profile/Profile', // eslint-disable-line
  component: Profile,
  parameters: { layout: `fullscreen` },
  decorators: [withStatefulChrome],
} satisfies Meta<typeof Profile>;

type Story = StoryObj<typeof meta>;

const notificationProps = {
  methodOptions: CardStory.args?.methodOptions!,
  updateMethod: CardStory.args?.updateMethod!,
  updateTrigger: CardStory.args?.updateTrigger!,
  saveButtonDisabled: false,
};

// @screenshot: xs,md
export const Default: Story = props({
  email: `johndoe@example.com`,
  status: `active`,
  methods: withIdsAnd({ deletable: false }, [
    { method: `email` as const, value: `me@example.com` },
    { method: `slack` as const, value: `#Gertrude` },
    { method: `email` as const, value: `you@example.com` },
    { method: `text` as const, value: `(123) 456-7890`, deletable: true },
  ]),
  notifications: withIdsAnd(notificationProps, [
    {
      selectedMethod: {
        type: `VerifiedEmailMethod` as const,
        value: { id: `1`, email: `me@example.com` },
      },
      trigger: `suspendFilterRequestSubmitted` as const,
      editing: true,
    },
    {
      selectedMethod: {
        type: `VerifiedSlackMethod` as const,
        value: {
          id: `2`,
          channelId: ``,
          channelName: `#Gertrude`,
          token: ``,
        },
      },
      trigger: `unlockRequestSubmitted` as const,
      editing: false,
    },
    {
      selectedMethod: {
        type: `VerifiedTextMethod` as const,
        value: {
          id: `3`,
          phoneNumber: `(555) 555-5555`,
        },
      },
      trigger: `suspendFilterRequestSubmitted` as const,
      editing: false,
    },
  ]),
  deleteMethod: confirmableEntityAction(),
  deleteNotification: confirmableEntityAction(),
  billingPortalRequest: { state: `idle` },
});

// @screenshot: xs,md
export const AddingMethod: Story = props({
  ...Default.args,
  pendingMethod: {
    type: `Email`,
    value: { email: `` },
    sendCodeRequest: { state: `idle` },
    confirmationRequest: { state: `idle` },
    confirmationCode: `333243`,
  },
});

// @screenshot: xs,md
export const AddingMethodVerifying: Story = props({
  ...Default.args,
  pendingMethod: {
    type: `Email`,
    value: { email: `` },
    sendCodeRequest: { state: `succeeded`, payload: `123456` },
    confirmationRequest: { state: `idle` },
    confirmationCode: `333234`,
  },
});

export default meta;
