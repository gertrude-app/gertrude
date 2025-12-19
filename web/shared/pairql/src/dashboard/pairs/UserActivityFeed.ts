// auto-generated, do not edit
import type { UserActivityItem } from '../shared';

export namespace UserActivityFeed {
  export interface Input {
    userId: UUID;
    range: {
      start: string;
      end: string;
    };
  }

  export interface Output {
    userName: string;
    showSuspensionActivity: boolean;
    numDeleted: number;
    items: UserActivityItem[];
  }
}
