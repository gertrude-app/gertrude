// auto-generated, do not edit
import type { AccountNotification, AccountNotificationMethod } from '../shared';

export namespace GetAccountSettings {
  export type Input = void;

  export interface Output {
    email: string;
    dailyReviewEmail: boolean;
    hasMacScreenshotUsers: boolean;
    notifications: AccountNotification[];
    notificationMethods: AccountNotificationMethod[];
  }
}
