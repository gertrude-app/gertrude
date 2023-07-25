// auto-generated, do not edit
import type { SuccessOutput } from '../shared';

export namespace DeleteEntity {
  export interface Input {
    id: UUID;
    type:
      | 'adminNotification'
      | 'adminVerifiedNotificationMethod'
      | 'userDevice'
      | 'key'
      | 'keychain'
      | 'user';
  }

  export type Output = SuccessOutput;
}
