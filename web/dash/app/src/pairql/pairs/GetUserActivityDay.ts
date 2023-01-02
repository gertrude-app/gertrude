// auto-generated, do not edit
import type Result from '../../lib/Result';
import { pqlQuery } from '../query';
import { ClientAuth } from '../shared';

export namespace GetUserActivityDay {
  export interface Input {
    userId: UUID;
    range: {
      start: string;
      end: string;
    };
  }

  export type Item =
    | {
        type: 'Screenshot';
        value: {
          id: UUID;
          ids: UUID[];
          url: string;
          width: number;
          height: number;
          createdAt: ISODateString;
        };
      }
    | {
        type: 'CoalescedKeystrokeLine';
        value: {
          id: UUID;
          ids: UUID[];
          appName: string;
          line: string;
          createdAt: ISODateString;
        };
      };

  export interface Output {
    userName: string;
    items: Array<Item>;
  }

  export async function fetch(input: Input): Promise<Result<Output, string>> {
    return pqlQuery<Input, Output>(input, ClientAuth.admin, `GetUserActivityDay`);
  }
}
