import { SubscriptionStatus, Trigger } from './GraphQL';

export interface Admin {
  email: string;
  subscriptionStatus: SubscriptionStatus;
}

export interface AdminIds {
  id: UUID;
  token: UUID;
}

export interface AdminNotificationMethod {
  id: UUID;
  data:
    | { type: `email`; email: string }
    | { type: `text`; phoneNumber: string }
    | { type: `slack`; token: string; channelName: string; channelId: string };
}

export interface Notification {
  id: UUID;
  trigger: Trigger;
  methodId: UUID;
}
