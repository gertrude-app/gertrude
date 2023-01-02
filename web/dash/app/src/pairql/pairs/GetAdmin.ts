// auto-generated, do not edit
import type { AdminNotificationTrigger } from '../shared';
import type Result from '../../lib/Result';
import { pqlQuery } from '../query';
import { ClientAuth } from '../shared';

export namespace GetAdmin {
  export type Input = void;

  export interface Output {
    id: UUID;
    email: string;
    notifications: Array<{
      id: UUID;
      trigger: AdminNotificationTrigger;
      methodId: UUID;
    }>;
    verifiedNotificationMethods: Array<
      | {
          type: 'VerifiedEmailMethod';
          value: {
            id: UUID;
            email: string;
          };
        }
      | {
          type: 'VerifiedSlackMethod';
          value: {
            id: UUID;
            channelId: string;
            channelName: string;
            token: string;
          };
        }
      | {
          type: 'VerifiedTextMethod';
          value: {
            id: UUID;
            phoneNumber: string;
          };
        }
    >;
  }

  export async function fetch(input: Input): Promise<Result<Output, string>> {
    return pqlQuery<Input, Output>(input, ClientAuth.admin, `GetAdmin`);
  }
}
