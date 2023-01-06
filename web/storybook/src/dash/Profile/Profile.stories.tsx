import { Profile } from '@dash/components';
import type { ComponentStory, ComponentMeta } from '@storybook/react';
import { withStatefulChrome } from '../../decorators/StatefulChrome';
import { withIdsAnd, confirmableEntityAction } from '../../story-helpers';
import { Email as CardStory } from './NotificationCard.stories';

export default {
  title: 'Dashboard/Profile/Profile', // eslint-disable-line
  component: Profile,
  parameters: { layout: `fullscreen` },
  decorators: [withStatefulChrome],
} as ComponentMeta<typeof Profile>;

const Template: ComponentStory<typeof Profile> = (args) => <Profile {...args} />;

const notificationProps = {
  methodOptions: CardStory.args?.methodOptions!,
  updateMethod: CardStory.args?.updateMethod!,
  updateTrigger: CardStory.args?.updateTrigger!,
  saveButtonDisabled: false,
};

// @screenshot: xs,md
export const Default = Template.bind({});
Default.args = {
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
};

// @screenshot: xs,md
export const AddingMethod = Template.bind({});
AddingMethod.args = {
  ...Default.args,
  pendingMethod: {
    type: `Email`,
    value: { email: `` },
    sendCodeRequest: { state: `idle` },
    confirmationRequest: { state: `idle` },
    confirmationCode: `333243`,
  },
};

// @screenshot: xs,md
export const AddingMethodVerifying = Template.bind({});
AddingMethodVerifying.args = {
  ...Default.args,
  pendingMethod: {
    type: `Email`,
    value: { email: `` },
    sendCodeRequest: { state: `succeeded`, payload: `123456` },
    confirmationRequest: { state: `idle` },
    confirmationCode: `333234`,
  },
};
