import { ComponentStory, ComponentMeta } from '@storybook/react';
import { withStatefulChrome } from '../../../decorators/StatefulChrome';
import { Trigger } from '../types/GraphQL';
import { withIdsAnd, confirmableEntityAction } from '../story-helpers';
import { Email as CardStory } from './NotificationCard/NotificationCard.stories';
import Profile from './Profile';

export default {
  title: `Dashboard/Profile`,
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
        id: `1`,
        data: { type: `email` as const, email: `me@example.com` },
      },
      trigger: Trigger.suspendFilterRequestSubmitted,
      editing: true,
    },
    {
      selectedMethod: {
        id: `2`,
        data: {
          type: `slack` as const,
          channelId: ``,
          channelName: `#Gertrude`,
          token: ``,
        },
      },
      trigger: Trigger.unlockRequestSubmitted,
      editing: false,
    },
    {
      selectedMethod: {
        id: `3`,
        data: { type: `text` as const, phoneNumber: `(555) 555-5555` },
      },
      trigger: Trigger.suspendFilterRequestSubmitted,
      editing: false,
    },
  ]),
  deleteMethod: confirmableEntityAction(),
  deleteNotification: confirmableEntityAction(),
};
