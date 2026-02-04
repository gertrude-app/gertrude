import { Settings } from '@dash/components';
import type { Plan } from '@dash/types';
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
};

const plans: Record<string, Plan> = {
  fullPaid: {
    case: `full`,
    status: { case: `paid`, stripeId: `sub_123`, monthlyPriceInCents: 1000 },
  },
  fullPaidLegacy: {
    case: `full`,
    status: { case: `paid`, stripeId: `sub_123`, monthlyPriceInCents: 500 },
  },
  fullTrialing: {
    case: `full`,
    status: {
      case: `trialing`,
      until: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString(),
    },
  },
  fullTrialingExpiringSoon: {
    case: `full`,
    status: {
      case: `trialing`,
      until: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString(),
    },
  },
  fullOverdue: {
    case: `full`,
    status: { case: `overdue`, stripeId: `sub_123`, monthlyPriceInCents: 1000 },
  },
  fullTrialExpired: { case: `full`, status: { case: `trialExpired` } },
  fullComplimentary: { case: `full`, status: { case: `complimentary` } },
  lightPaid: { case: `light`, status: { case: `paid`, stripeId: `sub_456` } },
  lightOverdue: { case: `light`, status: { case: `overdue`, stripeId: `sub_456` } },
  free: { case: `free`, kind: { case: `standard` } },
};

const baseArgs = {
  newMethodId: undefined,
  setNewMethodId: () => {},
  email: `johndoe@example.com`,
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
  billingPortalRequest: { state: `idle` as const },
  updateNotification: () => {},
  saveNotification: () => {},
  createNotification: () => {},
  manageSubscription: () => {},
  newMethodEventHandler: () => {},
};

// @screenshot: xs,md
export const Default: Story = props({
  ...baseArgs,
  plan: plans.fullPaid,
});

// @screenshot: xs,md
export const NoNotifications: Story = props({
  ...baseArgs,
  plan: plans.fullPaid,
  notifications: [],
});

// @screenshot: xs,md
export const AddingMethod: Story = props({
  ...baseArgs,
  plan: plans.fullPaid,
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
  ...baseArgs,
  plan: plans.fullPaid,
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
  ...baseArgs,
  plan: plans.fullPaid,
  newMethodId: {
    confirmed: true,
    id: `1`,
  },
});

export const FullTrialing: Story = props({
  ...baseArgs,
  plan: plans.fullTrialing,
});

export const FullTrialingExpiringSoon: Story = props({
  ...baseArgs,
  plan: plans.fullTrialingExpiringSoon,
});

export const FullOverdue: Story = props({
  ...baseArgs,
  plan: plans.fullOverdue,
});

export const FullTrialExpired: Story = props({
  ...baseArgs,
  plan: plans.fullTrialExpired,
});

export const FullPaidLegacy: Story = props({
  ...baseArgs,
  plan: plans.fullPaidLegacy,
});

export const FullComplimentary: Story = props({
  ...baseArgs,
  plan: plans.fullComplimentary,
});

export const LightPaid: Story = props({
  ...baseArgs,
  plan: plans.lightPaid,
});

export const LightOverdue: Story = props({
  ...baseArgs,
  plan: plans.lightOverdue,
});

export const Free: Story = props({
  ...baseArgs,
  plan: plans.free,
});

export default meta;
