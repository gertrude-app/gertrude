// auto-generated, do not edit
import type { AdminNotificationTrigger } from '../shared';

export namespace SaveNotification_v0 {
  export interface Input {
    id?: UUID;
    methodId: UUID;
    trigger: AdminNotificationTrigger;
  }

  export interface Output {
    id: UUID;
  }
}
