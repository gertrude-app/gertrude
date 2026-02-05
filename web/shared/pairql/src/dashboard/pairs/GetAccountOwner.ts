// auto-generated, do not edit
import type { AdminNotification, Plan, VerifiedNotificationMethod } from '../shared';

export namespace GetAccountOwner {
  export type Input = void;

  export interface Output {
    id: UUID;
    email: string;
    plan: Plan;
    notifications: AdminNotification[];
    verifiedNotificationMethods: VerifiedNotificationMethod[];
  }
}
