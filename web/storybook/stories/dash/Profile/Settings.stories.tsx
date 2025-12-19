import { Settings } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { withStatefulChrome } from '../../decorators/StatefulChrome';
import { confirmableEntityAction, props, withIdsAnd } from '../../story-helpers';
import { Email as CardStory } from './NotificationCard.stories';

const meta = {
  title: 'Dashboard/Settings/Settings', // eslint-disable-line
  component: Settings,
  parameters: { layout: `fullscreen` },
  decorators: [withStatefulChrome],
} satisfies Meta<typeof Settings>;

type Story = StoryObj<typeof meta>;

const notificationProps = {
  methodOptions: CardStory.args?.methodOptions!,
  updateMethod: CardStory.args?.updateMethod!,
  updateTrigger: CardStory.args?.updateTrigger!,
  saveButtonDisabled: false,
  showSecurityEventOption: false,
};

// @screenshot: xs,md
export const Default: Story = props({
  newMethodId: undefined,
  setNewMethodId: () => {},
  email: `johndoe@example.com`,
  status: { case: `paid` },
  monthlyPriceInDollars: 10,
  methods: withIdsAnd({ deletable: false }, [
    { method: `email` as const, value: `me@example.com`, inUse: true },
    { method: `slack` as const, value: `#Gertrude`, inUse: true },
    { method: `email` as const, value: `you@example.com`, inUse: false },
    { method: `text` as const, value: `(123) 456-7890`, deletable: true, inUse: true },
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
          phoneNumber: `(123) 456-7890`,
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
  updateNotification: () => {},
  saveNotification: () => {},
  createNotification: () => {},
  manageSubscription: () => {},
  newMethodEventHandler: () => {},
});

// @screenshot: xs,md
export const NoNotifications: Story = props({
  ...Default.args,
  notifications: [],
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

// @screenshot: xs,md
export const AfterNewMethodCreation: Story = props({
  ...Default.args,
  newMethodId: {
    confirmed: true,
    id: `1`,
  },
});

export default meta;
