// auto-generated, do not edit
import type { AdminNotificationTrigger } from '../shared';

export namespace GetAdmin {
  export type Input = void;

  export type VerifiedNotificationMethod =
    | {
        type: 'VerifiedEmailMethod';
        value: {
          id: UUID;
          email: string;
        };
      }
    | {
        type: 'VerifiedSlackMethod';
        value: {
          id: UUID;
          channelId: string;
          channelName: string;
          token: string;
        };
      }
    | {
        type: 'VerifiedTextMethod';
        value: {
          id: UUID;
          phoneNumber: string;
        };
      };

  export interface Notification {
    id: UUID;
    trigger: AdminNotificationTrigger;
    methodId: UUID;
  }

  export enum SubscriptionStatus {
    pendingEmailVerification,
    emailVerified,
    signupCanceled,
    complimentary,
    incomplete,
    incompleteExpired,
    trialing,
    active,
    pastDue,
    canceled,
    unpaid,
  }

  export interface Output {
    id: UUID;
    email: string;
    subscriptionStatus: SubscriptionStatus;
    notifications: Array<Notification>;
    verifiedNotificationMethods: Array<VerifiedNotificationMethod>;
  }
}
