import type {
  GetAccountKeychain,
  GetAccountKeychains,
  GetActivitySummaries,
  GetDayActivity,
  GetDevices,
  GetPeople,
  GetPersonActivitySummaries,
  GetPersonDayActivity,
  GetPersonInstalledMacApps,
  GetPersonMacSettings,
  GetSecurityEvents,
  GetSuspensionRequests,
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

  static get devices(): QueryKey<GetDevices.Output> {
    return new QueryKey([`devices`]);
  }

  static get keychains(): QueryKey<GetAccountKeychains.Output> {
    return new QueryKey([`keychains`]);
  }

  static keychain(keychainId: string): QueryKey<GetAccountKeychain.Output> {
    return new QueryKey([`keychains`, keychainId]);
  }

  static get suspensionRequests(): QueryKey<GetSuspensionRequests.Output> {
    return new QueryKey([`requests`, `suspension`]);
  }

  static get securityEvents(): QueryKey<GetSecurityEvents.Output> {
    return new QueryKey([`security-events`]);
  }

  static get activity(): QueryKey<unknown> {
    return new QueryKey([`activity`]);
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

  static personMacSettings(personId: string): QueryKey<GetPersonMacSettings.Output> {
    return new QueryKey([`people`, personId, `mac-settings`]);
  }

  static personInstalledMacApps(
    personId: string,
  ): QueryKey<GetPersonInstalledMacApps.Output> {
    return new QueryKey([`people`, personId, `installed-mac-apps`]);
  }

  private constructor() {
    super([]);
  }
}
