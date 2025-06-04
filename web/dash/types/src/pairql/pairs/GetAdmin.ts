// auto-generated, do not edit
import type {
  AdminNotification,
  AdminSubscriptionStatus,
  VerifiedNotificationMethod,
} from '../shared';

export namespace GetAdmin {
  export type Input = void;

  export interface Output {
    id: UUID;
    email: string;
    subscriptionStatus: AdminSubscriptionStatus;
    notifications: AdminNotification[];
    verifiedNotificationMethods: VerifiedNotificationMethod[];
    hasAdminChild: boolean;
    monthlyPriceInDollars: number;
  }
}
