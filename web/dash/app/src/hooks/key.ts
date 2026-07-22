import type {
  ChildActivitySummaries,
  CombinedUsersActivityFeed,
  DashboardWidgets_v3,
  FamilyActivitySummaries,
  GetAccountOwner_v2,
  GetAdminKeychain,
  GetAdminKeychains,
  GetAllDevices,
  GetAmClaimData,
  GetBatchUnlockRequestData,
  GetBlockerClaimData,
  GetChild,
  GetChildren,
  GetDevice,
  GetIOSDeviceClaimData,
  GetIOSDeviceSupervisionStatus,
  GetIOSDevice_v2,
  GetIdentifiedApps,
  GetInstalledMacApps,
  GetMusicAlbumCuration,
  GetMusicClaimData,
  GetMusicCuration,
  GetSelectableKeychains,
  GetSubscriptionPanel_v2,
  GetSuspendFilterRequest,
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
    return new QueryKey(`children/:id`, [`children`, id], id);
  }

  static musicCuration(id: UUID): QueryKey<GetMusicCuration.Output> {
    return new QueryKey(
      `children/:id/music-curation`,
      [`children`, id, `music`, `curation`],
      id,
    );
  }

  static musicAlbumCuration(
    childId: UUID,
    albumId: string,
  ): QueryKey<GetMusicAlbumCuration.Output> {
    return new QueryKey(
      `children/:id/music-curation/:album-id`,
      [`children`, childId, `music`, `curation`, albumId],
      childId,
    );
  }

  static installedMacApps(id: UUID): QueryKey<GetInstalledMacApps.Output> {
    return new QueryKey(
      `children/:id/installed-mac-apps`,
      [`children`, id, `installed-mac-apps`],
      id,
    );
  }

  static get latestAppVersions(): QueryKey<LatestAppVersions.Output> {
    return new QueryKey(`latest-app-versions`, [`latest-app-versions`]);
  }

  static get allDevices(): QueryKey<GetAllDevices.Output> {
    return new QueryKey(`devices`, [`devices`]);
  }

  static computer(id: UUID): QueryKey<GetDevice.Output> {
    return new QueryKey(`computers/:id`, [`computers`, id], id);
  }

  static iOSDevice(id: UUID): QueryKey<GetIOSDevice_v2.Output> {
    return new QueryKey(`ios-devices/:id`, [`ios-devices`, id], id);
  }

  static childActivitySummaries(id: UUID): QueryKey<ChildActivitySummaries.Output> {
    return new QueryKey(`children/:id/activity`, [`children`, id, `activity`], id);
  }

  static userActivityFeed(id: UUID, day: string): QueryKey<UserActivityFeed.Output> {
    return new QueryKey(
      `children/:id/activity/:day`,
      [`children`, id, `activity`, day],
      id,
    );
  }

  static get selectableKeychains(): QueryKey<GetSelectableKeychains.Output> {
    return new QueryKey(`selectable-keychains`, [`selectable-keychains`]);
  }

  static get dashboard(): QueryKey<DashboardWidgets_v3.Output> {
    return new QueryKey(`dashboard`, [`dashboard`]);
  }

  static get familyActivitySummaries(): QueryKey<FamilyActivitySummaries.Output> {
    return new QueryKey(`children/activity`, [`children`, `activity`]);
  }

  static combinedUsersActivityFeed(
    day: string,
  ): QueryKey<CombinedUsersActivityFeed.Output> {
    return new QueryKey(`children/activity/:day`, [`children`, `activity`, day]);
  }

  static get adminKeychains(): QueryKey<GetAdminKeychains.Output> {
    return new QueryKey(`admin-keychains`, [`admin-keychains`]);
  }

  static adminKeychain(id: UUID): QueryKey<GetAdminKeychain.Output> {
    return new QueryKey(`admin-keychains/:id`, [`admin-keychains`, id], id);
  }

  static batchUnlockRequestData(id: UUID): QueryKey<GetBatchUnlockRequestData.Output> {
    return new QueryKey(
      `children/:id/batch-unlock-requests`,
      [`children`, id, `batch-unlock-requests`],
      id,
    );
  }

  static suspendFilterRequest(id: UUID): QueryKey<GetSuspendFilterRequest.Output> {
    return new QueryKey(`suspend-filter-requests/:id`, [`suspend-filter-requests`, id]);
  }

  static get accountOwner(): QueryKey<GetAccountOwner_v2.Output> {
    return new QueryKey(`account-owner`, [`account-owner`]);
  }

  static get subscriptionPanel(): QueryKey<GetSubscriptionPanel_v2.Output> {
    return new QueryKey(`subscription-panel`, [`subscription-panel`]);
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

  static amClaimData(code: string): QueryKey<GetAmClaimData.Output> {
    return new QueryKey(`am-claim-device/:code`, [`am-claim-device`, code]);
  }

  static musicClaimData(code: string): QueryKey<GetMusicClaimData.Output> {
    return new QueryKey(`music-claim-device/:code`, [`music-claim-device`, code]);
  }

  static blockerClaimData(code: string): QueryKey<GetBlockerClaimData.Output> {
    return new QueryKey(`blocker-claim-device/:code`, [`blocker-claim-device`, code]);
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
