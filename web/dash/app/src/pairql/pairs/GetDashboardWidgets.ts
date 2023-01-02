// auto-generated, do not edit
import type Result from '../../lib/Result';
import { pqlQuery } from '../query';
import { ClientAuth } from '../shared';

export namespace GetDashboardWidgets {
  export type Input = void;

  export interface Output {
    users: Array<{
      id: UUID;
      userName: string;
      isOnline: boolean;
    }>;
    userActivitySummaries: Array<{
      id: UUID;
      name: string;
      numUnreviewed: number;
      numReviewed: number;
    }>;
    unlockRequests: Array<{
      id: UUID;
      userId: UUID;
      userName: string;
      target: string;
      comment?: string;
      createdAt: ISODateString;
    }>;
    recentScreenshots: Array<{
      id: UUID;
      userName: string;
      url: string;
      createdAt: ISODateString;
    }>;
  }

  export async function fetch(input: Input): Promise<Result<Output, string>> {
    return pqlQuery<Input, Output>(input, ClientAuth.admin, `GetDashboardWidgets`);
  }
}
