// auto-generated, do not edit
import type { GertrudeApp } from '../shared';

export namespace AppRatings {
  export interface Input {
    app: GertrudeApp;
  }

  export interface Output {
    app: GertrudeApp;
    currentAverage: number;
    totalCount: number;
    items: Array<{
      type: `review` | `ratingEvent`;
      id: UUID;
      stars: number;
      date: ISODateString;
      title?: string;
      body?: string;
      reviewer?: string;
      territory?: string;
    }>;
  }
}
