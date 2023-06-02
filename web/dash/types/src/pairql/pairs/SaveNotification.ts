// auto-generated, do not edit
import type { AdminNotificationTrigger, SuccessOutput } from '../shared';

export namespace SaveNotification {
  export interface Input {
    id: UUID;
    isNew: boolean;
    methodId: UUID;
    trigger: AdminNotificationTrigger;
  }

  export type Output = SuccessOutput;
}
