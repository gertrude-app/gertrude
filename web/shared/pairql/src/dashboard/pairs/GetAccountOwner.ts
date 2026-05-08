// auto-generated, do not edit
import type {
  AdminNotification,
  Entitlement,
  VerifiedNotificationMethod,
} from '../shared';

export namespace GetAccountOwner {
  export type Input = void;

  export interface Output {
    id: UUID;
    email: string;
    entitlement: Entitlement;
    notifications: AdminNotification[];
    verifiedNotificationMethods: VerifiedNotificationMethod[];
  }
}
