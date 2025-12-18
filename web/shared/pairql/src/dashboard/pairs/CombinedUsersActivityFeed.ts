// auto-generated, do not edit
import type { UserActivityItem } from '../shared';

export namespace CombinedUsersActivityFeed {
  export interface Input {
    range: {
      start: string;
      end: string;
    };
  }

  export type Output = Array<{
    userName: string;
    showSuspensionActivity: boolean;
    numDeleted: number;
    items: UserActivityItem[];
  }>;
}
