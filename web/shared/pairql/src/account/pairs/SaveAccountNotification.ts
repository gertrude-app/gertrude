// auto-generated, do not edit
import type { NotificationTrigger, SuccessOutput } from '../shared';

export namespace SaveAccountNotification {
  export interface Input {
    id: UUID;
    isNew: boolean;
    methodId: UUID;
    trigger: NotificationTrigger;
  }

  export type Output = SuccessOutput;
}
