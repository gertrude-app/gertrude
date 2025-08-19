// auto-generated, do not edit
import type { SuccessOutput } from '../shared';

export namespace DeleteEntity_v2 {
  export interface Input {
    id: UUID;
    type:
      | `announcement`
      | `child`
      | `computerUser`
      | `parent`
      | `parentNotification`
      | `parentVerifiedNotificationMethod`
      | `key`
      | `keychain`
      | `blockRule`;
  }

  export type Output = SuccessOutput;
}
