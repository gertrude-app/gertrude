// auto-generated, do not edit
import type Result from '../../lib/Result';
import { pqlQuery } from '../query';
import { ClientAuth } from '../shared';

export namespace CreatePendingNotificationMethod {
  export type Input =
    | {
        type: 'EmailInput';
        value: {
          email: string;
        };
      }
    | {
        type: 'TextInput';
        value: {
          phoneNumber: string;
        };
      }
    | {
        type: 'SlackInput';
        value: {
          token: string;
          channelId: string;
          channelName: string;
        };
      };

  export interface Output {
    methodId: UUID;
  }

  export async function fetch(input: Input): Promise<Result<Output, string>> {
    return pqlQuery<Input, Output>(
      input,
      ClientAuth.admin,
      `CreatePendingNotificationMethod`,
    );
  }
}
