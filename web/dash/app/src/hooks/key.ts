import type {
  GetUsers,
  GetUser,
  ChildActivitySummaries,
  UserActivityFeed,
  GetSelectableKeychains,
  DashboardWidgets,
  FamilyActivitySummaries,
  CombinedUsersActivityFeed,
  GetAdminKeychains,
  GetIdentifiedApps,
  GetAdminKeychain,
  GetUnlockRequest,
  GetUserUnlockRequests,
  GetUnlockRequests,
  GetSuspendFilterRequest,
  GetAdmin,
  GetDevices,
  GetDevice,
  LatestAppVersions,
  SecurityEventsFeed,
} from '@dash/types';

export class QueryKey<T> {
  private phantom?: T;

  // do not construct directly, use `Key` static methods
  public readonly __taint: `66e66bd61e2f4e009ca94f3fac98fd33`;

  protected constructor(
    public readonly path: string,
    public readonly segments: unknown[],
    public readonly id?: UUID,
  ) {
    this.__taint = `66e66bd61e2f4e009ca94f3fac98fd33`;
  }

  public get data(): QueryKeyData {
    return { path: this.path, segments: this.segments, id: this.id };
  }
}

export class Key extends QueryKey<never> {
  static get users(): QueryKey<GetUsers.Output> {
    return new QueryKey(`users`, [`users`]);
  }

  static user(id: UUID): QueryKey<GetUser.Output> {
    return new QueryKey(`users/:id`, [`users`, id], id);
  }

  static get devices(): QueryKey<GetDevices.Output> {
    return new QueryKey(`computers`, [`computers`]);
  }

  static get latestAppVersions(): QueryKey<LatestAppVersions.Output> {
    return new QueryKey(`latest-app-versions`, [`latest-app-versions`]);
  }

  static device(id: UUID): QueryKey<GetDevice.Output> {
    return new QueryKey(`computers/:id`, [`computers`, id], id);
  }

  static childActivitySummaries(id: UUID): QueryKey<ChildActivitySummaries.Output> {
    return new QueryKey(`users/:id/activity`, [`users`, id, `activity`], id);
  }

  static userActivityFeed(id: UUID, day: string): QueryKey<UserActivityFeed.Output> {
    return new QueryKey(`users/:id/activity/:day`, [`users`, id, `activity`, day], id);
  }

  static get selectableKeychains(): QueryKey<GetSelectableKeychains.Output> {
    return new QueryKey(`selectable-keychains`, [`selectable-keychains`]);
  }

  static get dashboard(): QueryKey<DashboardWidgets.Output> {
    return new QueryKey(`dashboard`, [`dashboard`]);
  }

  static get familyActivitySummaries(): QueryKey<FamilyActivitySummaries.Output> {
    return new QueryKey(`users/activity`, [`users`, `activity`]);
  }

  static combinedUsersActivityFeed(
    day: string,
  ): QueryKey<CombinedUsersActivityFeed.Output> {
    return new QueryKey(`users/activity/:day`, [`users`, `activity`, day]);
  }

  static get adminKeychains(): QueryKey<GetAdminKeychains.Output> {
    return new QueryKey(`admin-keychains`, [`admin-keychains`]);
  }

  static adminKeychain(id: UUID): QueryKey<GetAdminKeychain.Output> {
    return new QueryKey(`admin-keychains/:id`, [`admin-keychains`, id], id);
  }

  static userUnlockRequests(id: UUID): QueryKey<GetUserUnlockRequests.Output> {
    return new QueryKey(
      `users/:id/unlock-requests`,
      [`users`, id, `unlock-requests`],
      id,
    );
  }

  static get combinedUsersUnlockRequests(): QueryKey<GetUnlockRequests.Output> {
    return new QueryKey(`unlock-requests`, [`unlock-requests`]);
  }

  static unlockRequest(id: UUID): QueryKey<GetUnlockRequest.Output> {
    return new QueryKey(`unlock-requests/:id`, [`unlock-requests`, id]);
  }

  static suspendFilterRequest(id: UUID): QueryKey<GetSuspendFilterRequest.Output> {
    return new QueryKey(`suspend-filter-requests/:id`, [`suspend-filter-requests`, id]);
  }

  static get admin(): QueryKey<GetAdmin.Output> {
    return new QueryKey(`admin`, [`admin`]);
  }

  static get apps(): QueryKey<GetIdentifiedApps.Output> {
    return new QueryKey(`apps`, [`apps`]);
  }

  static get securityEventsFeed(): QueryKey<SecurityEventsFeed.Output> {
    return new QueryKey(`securityEvents`, [`securityEvents`]);
  }

  private constructor() {
    super(``, []);
  }
}

export type QueryKeyData = Omit<QueryKey<any>, 'data' | '__taint' | 'phantom'>;
