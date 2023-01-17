// auto-generated, do not edit
import type { AdminNotificationTrigger, AdminSubscriptionStatus } from '../shared';

export namespace GetAdmin {
  export type Input = void;

  export interface Notification {
    id: UUID;
    trigger: AdminNotificationTrigger;
    methodId: UUID;
  }

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

  export interface Output {
    id: UUID;
    email: string;
    subscriptionStatus: AdminSubscriptionStatus;
    notifications: Array<Notification>;
    verifiedNotificationMethods: Array<VerifiedNotificationMethod>;
  }
}
