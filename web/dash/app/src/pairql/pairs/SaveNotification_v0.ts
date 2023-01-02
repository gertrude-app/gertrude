// auto-generated, do not edit
import type { AdminNotificationTrigger } from '../shared';
import type Result from '../../lib/Result';
import { pqlQuery } from '../query';
import { ClientAuth } from '../shared';

export namespace SaveNotification_v0 {
  export interface Input {
    id?: UUID;
    methodId: UUID;
    trigger: AdminNotificationTrigger;
  }

  export interface Output {
    id: UUID;
  }

  export async function fetch(input: Input): Promise<Result<Output, string>> {
    return pqlQuery<Input, Output>(input, ClientAuth.admin, `SaveNotification_v0`);
  }
}
