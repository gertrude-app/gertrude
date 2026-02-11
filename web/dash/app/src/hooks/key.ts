import type {
  ChildActivitySummaries,
  CombinedUsersActivityFeed,
  DashboardWidgets,
  FamilyActivitySummaries,
  GetAccountOwner,
  GetAdminKeychain,
  GetAdminKeychains,
  GetChild,
  GetChildren,
  GetDevice,
  GetDevices,
  GetIOSDevice,
  GetIOSDeviceClaimData,
  GetIOSDeviceSupervisionStatus,
  GetIdentifiedApps,
  GetSelectableKeychains,
  GetSuspendFilterRequest,
  GetUnlockRequest,
  GetUnlockRequests,
  GetUserUnlockRequests,
  IOSDevices,
  LatestAppVersions,
  SecurityEventsFeed,
  UserActivityFeed,
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
  static get children(): QueryKey<GetChildren.Output> {
    return new QueryKey(`children`, [`children`]);
  }

  static child(id: UUID): QueryKey<GetChild.Output> {
    return new QueryKey(`users/:id`, [`users`, id], id);
  }

  static get latestAppVersions(): QueryKey<LatestAppVersions.Output> {
    return new QueryKey(`latest-app-versions`, [`latest-app-versions`]);
  }

  static get computers(): QueryKey<GetDevices.Output> {
    return new QueryKey(`computers`, [`computers`]);
  }

  static computer(id: UUID): QueryKey<GetDevice.Output> {
    return new QueryKey(`computers/:id`, [`computers`, id], id);
  }

  static get iOSDevices(): QueryKey<IOSDevices.Output> {
    return new QueryKey(`ios-devices`, [`ios-devices`]);
  }

  static iOSDevice(id: UUID): QueryKey<GetIOSDevice.Output> {
    return new QueryKey(`ios-devices/:id`, [`ios-devices`, id], id);
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

  static get accountOwner(): QueryKey<GetAccountOwner.Output> {
    return new QueryKey(`account-owner`, [`account-owner`]);
  }

  static get apps(): QueryKey<GetIdentifiedApps.Output> {
    return new QueryKey(`apps`, [`apps`]);
  }

  static get securityEventsFeed(): QueryKey<SecurityEventsFeed.Output> {
    return new QueryKey(`securityEvents`, [`securityEvents`]);
  }

  static claimDeviceData(code: string): QueryKey<GetIOSDeviceClaimData.Output> {
    return new QueryKey(`claim-device/:code`, [`claim-device`, code]);
  }

  static supervisionDeviceStatus(
    code: string,
  ): QueryKey<GetIOSDeviceSupervisionStatus.Output> {
    return new QueryKey(`supervision-device/:code`, [`supervision-device`, code]);
  }

  private constructor() {
    super(``, []);
  }
}

export type QueryKeyData = Omit<QueryKey<any>, `data` | `__taint` | `phantom`>;
