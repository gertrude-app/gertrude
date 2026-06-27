import type {
  GetActivitySummaries,
  GetDayActivity,
  GetPeople,
  GetPersonActivitySummaries,
  GetPersonDayActivity,
} from '@shared/pairql/src/account';

export class QueryKey<T> {
  // phantom: ties the key to its operation's Output type for type-safe cache writes
  protected phantom?: T;

  // do not construct directly, use `Key` static methods
  protected constructor(public readonly segments: readonly unknown[]) {}
}

export class Key extends QueryKey<never> {
  static get people(): QueryKey<GetPeople.Output> {
    return new QueryKey([`people`]);
  }

  static get activitySummaries(): QueryKey<GetActivitySummaries.Output> {
    return new QueryKey([`activity`, `all`, `summaries`]);
  }

  static dayActivity(day: string): QueryKey<GetDayActivity.Output> {
    return new QueryKey([`activity`, `all`, day]);
  }

  static personActivitySummaries(
    personId: string,
  ): QueryKey<GetPersonActivitySummaries.Output> {
    return new QueryKey([`activity`, personId, `summaries`]);
  }

  static personDayActivity(
    personId: string,
    day: string,
  ): QueryKey<GetPersonDayActivity.Output> {
    return new QueryKey([`activity`, personId, day]);
  }

  private constructor() {
    super([]);
  }
}
