// auto-generated, do not edit
import type { SuccessOutput } from '../shared';

export namespace DeleteEntity {
  export interface Input {
    id: UUID;
    type:
      | 'AdminNotification'
      | 'AdminVerifiedNotificationMethod'
      | 'Device'
      | 'Key'
      | 'Keychain'
      | 'User';
  }

  export type Output = SuccessOutput;
}
