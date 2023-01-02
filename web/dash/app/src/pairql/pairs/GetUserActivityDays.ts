// auto-generated, do not edit
import type Result from '../../lib/Result';
import { pqlQuery } from '../query';
import { ClientAuth } from '../shared';

export namespace GetUserActivityDays {
  export interface Input {
    userId: UUID;
    dateRanges: Array<{
      start: string;
      end: string;
    }>;
  }

  export interface Output {
    userName: string;
    days: Array<{
      date: ISODateString;
      numApproved: number;
      totalItems: number;
    }>;
  }

  export async function fetch(input: Input): Promise<Result<Output, string>> {
    return pqlQuery<Input, Output>(input, ClientAuth.admin, `GetUserActivityDays`);
  }
}
