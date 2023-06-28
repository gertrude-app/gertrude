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
        id: `1`,
        config: { case: `email` as const, email: `me@example.com` },
      },
      trigger: `suspendFilterRequestSubmitted` as const,
      editing: true,
      isNew: false,
    },
    {
      selectedMethod: {
        id: `2`,
        config: {
          case: `slack` as const,
          channelId: ``,
          channelName: `#Gertrude`,
          token: ``,
        },
      },
      trigger: `unlockRequestSubmitted` as const,
      editing: false,
      isNew: false,
    },
    {
      selectedMethod: {
        id: `3`,
        config: {
          case: `text` as const,
          phoneNumber: `(555) 555-5555`,
        },
      },
      trigger: `suspendFilterRequestSubmitted` as const,
      editing: false,
      isNew: false,
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
    case: `email`,
    email: ``,
    sendCodeRequest: { state: `idle` },
    confirmationRequest: { state: `idle` },
    confirmationCode: `333243`,
  },
});

// @screenshot: xs,md
export const AddingMethodVerifying: Story = props({
  ...Default.args,
  pendingMethod: {
    case: `email`,
    email: ``,
    sendCodeRequest: { state: `succeeded`, payload: `123456` },
    confirmationRequest: { state: `idle` },
    confirmationCode: `333234`,
  },
});

export default meta;
