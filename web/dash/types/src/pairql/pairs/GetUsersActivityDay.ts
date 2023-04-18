// auto-generated, do not edit
import type { GetUserActivityDay } from './GetUserActivityDay';

export namespace GetUsersActivityDay {
  export interface Input {
    range: {
      start: string;
      end: string;
    };
  }

  export type Output = Array<GetUserActivityDay.Output & { userId: UUID }>;
}
