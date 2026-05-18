// auto-generated, do not edit
import type { AdminNotification, VerifiedNotificationMethod } from '../shared';

export namespace GetAccountOwner_v2 {
  export type Input = void;

  export interface Output {
    id: UUID;
    email: string;
    notifications: AdminNotification[];
    verifiedNotificationMethods: VerifiedNotificationMethod[];
  }
}
