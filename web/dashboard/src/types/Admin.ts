import { SubscriptionStatus, Trigger } from '../graphqlTypes';

export interface Admin {
  email: EmailAddress;
  subscriptionStatus: SubscriptionStatus;
}

export interface AdminIds {
  id: UUID;
  token: UUID;
}

export interface VerifiedNotificationMethod {
  id: UUID;
  data:
    | { type: `email`; email: EmailAddress }
    | { type: `text`; phoneNumber: string }
    | { type: `slack`; token: string; channelName: string; channelId: string };
}

export interface Notification {
  id: UUID;
  trigger: Trigger;
  methodId: UUID;
}
