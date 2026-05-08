import { Result } from '@shared/pairql';
import type { ApiClient } from './client';

const noopClient: ApiClient = {
  confirmPendingNotificationMethod: async () => {
    return Result.success({ success: true });
  },
  prepIOSAppConnection: async () => {
    return Result.success({ code: 0 });
  },
  iOSAppConnectionCode: async () => {
    return Result.success({ code: 0 });
  },
  macAppConnectionCode: async () => {
    return Result.success({ code: 0 });
  },
  createPendingNotificationMethod: async () => {
    return Result.success({ methodId: `` });
  },
  deleteActivityItems: async () => {
    return Result.success({ success: true });
  },
  deleteEntity: async () => {
    return Result.success({ success: true });
  },
  flagActivityItems: async () => {
    return Result.success({ success: true });
  },
  getAccountOwner: async () => {
    return Result.success({
      id: ``,
      email: ``,
      entitlement: { case: `full` },
      notifications: [],
      verifiedNotificationMethods: [],
    });
  },
  getAdminKeychain: async () => {
    return Result.success({
      children: [],
      summary: {
        id: ``,
        parentId: ``,
        name: ``,
        description: ``,
        isPublic: false,
        numKeys: 0,
      },
      keys: [],
    });
  },
  getAdminKeychains: async () => {
    return Result.success({ children: [], keychains: [], hasAnyMacComputers: false });
  },
  getIOSDeviceClaimData: async () => {
    return Result.success({
      children: [],
      modelName: `iPhone 15 Pro`,
      deviceType: `iPhone`,
      iosVersion: `26.2`,
    });
  },
  claimIOSDevice: async () => {
    return Result.success({
      childName: `Luke`,
      modelName: `iPhone 15 Pro`,
      iosVersion: `18.2`,
      code: 123456,
    });
  },
  getChild: async () => {
    return Result.success({
      id: ``,
      name: ``,
      keyloggingEnabled: false,
      screenshotsEnabled: false,
      screenshotsResolution: 1000,
      screenshotsFrequency: 90,
      showSuspensionActivity: true,
      filteringDisabled: false,
      canDisableFilter: false,
      keychains: [],
      computers: [],
      iosDevices: [],
      availableAlwaysBlockedGroups: [],
      alwaysBlockedGroupIds: [],
      customAlwaysBlockedRules: [],
      supportsAlwaysBlocked: false,
      createdAt: new Date().toISOString(),
    });
  },
  getChildren: async () => {
    return Result.success([]);
  },
  dashboardWidgets: async () => {
    return Result.success({
      children: [],
      childActivitySummaries: [],
      unlockRequests: [],
      recentScreenshots: [],
      numParentNotifications: 0,
      pendingIOSDevices: [],
    });
  },
  getIdentifiedApps: async () => {
    return Result.success([]);
  },
  getSelectableKeychains: async () => {
    return Result.success({ own: [], public: [] });
  },
  getIOSDeviceSupervisionStatus: async () => {
    return Result.success({
      deviceId: `device-123`,
      childId: `child-456`,
      childName: `Luke`,
      modelName: `iPhone 15 Pro`,
      deviceType: `iPhone`,
      iosVersion: `18.2`,
      supervisionStatus: `awaitingSupervision` as const,
      requiresPayment: true,
    });
  },
  getSuspendFilterRequest: async () => {
    return Result.success({
      id: ``,
      deviceId: ``,
      userName: ``,
      userId: ``,
      requestedDurationInSeconds: 0,
      requestComment: ``,
      status: `rejected`,
      createdAt: new Date().toISOString(),
      extraMonitoringOptions: {},
    });
  },
  getBatchUnlockRequestData: async () => {
    return Result.success({ requests: [], keychains: [] });
  },
  getAllDevices: async () => {
    return Result.success({ computers: [], iosDevices: [] });
  },
  getDevice: async () => {
    return Result.success({
      id: ``,
      name: undefined,
      releaseChannel: `stable`,
      appVersion: ``,
      users: [],
      serialNumber: ``,
      modelIdentifier: ``,
      modelFamily: `unknown`,
      modelTitle: ``,
    });
  },
  handleUnlockRequests: async () => {
    return Result.success({ success: true });
  },
  handleCheckoutCancel: async () => {
    return Result.success({ success: true });
  },
  handleCheckoutSuccess: async () => {
    return Result.success({ success: true });
  },
  getIOSDevice: async () => {
    return Result.success({
      childName: `Little Jimmy`,
      deviceType: `iPhone`,
      osVersion: `18.1.0`,
      allBlockGroups: [],
      enabledBlockGroups: [],
      webPolicy: `blockAllExcept`,
      webPolicyDomains: [],
      customBlockRules: [],
      isSupervised: false,
      isProfileLocked: true,
      allowAppRemoval: false,
      allowEraseContentAndSettings: false,
    });
  },
  userActivityFeed: async () => {
    return Result.success({
      numDeleted: 0,
      userName: ``,
      showSuspensionActivity: true,
      items: [],
    });
  },
  combinedUsersActivityFeed: async () => {
    return Result.success([]);
  },
  childActivitySummaries: async () => {
    return Result.success({ childName: ``, days: [] });
  },
  familyActivitySummaries: async () => {
    return Result.success([]);
  },
  decideFilterSuspensionRequest: async () => {
    return Result.success({ success: true });
  },
  latestAppVersions: async () => {
    return Result.success({
      stable: ``,
      beta: ``,
      canary: ``,
    });
  },
  login: async () => {
    return Result.success({ token: ``, adminId: `` });
  },
  loginMagicLink: async () => {
    return Result.success({ token: ``, adminId: `` });
  },
  logEvent: async () => {
    return Result.success({ success: true });
  },
  requestMagicLink: async () => {
    return Result.success({ success: true });
  },
  resetPassword: async () => {
    return Result.success({ success: true });
  },
  saveConferenceEmail: async () => {
    return Result.success({ success: true });
  },
  saveKey: async () => {
    return Result.success({ success: true });
  },
  saveKeychain: async () => {
    return Result.success({ success: true });
  },
  saveNotification: async () => {
    return Result.success({ success: true });
  },
  saveUser: async () => {
    return Result.success({ success: true });
  },
  saveDevice: async () => {
    return Result.success({ success: true });
  },
  sendPasswordResetEmail: async () => {
    return Result.success({ success: true });
  },
  signup: async () => {
    return Result.success({});
  },
  startFullTrial: async () => {
    return Result.success(undefined);
  },
  openBillingPortal: async () => {
    return Result.success({ url: `/` });
  },
  upgradeSubscriptionTier: async () => {
    return Result.success({ success: true });
  },
  getSubscriptionPanel: async () => {
    return Result.success({
      entitlement: { case: `full` },
      billing: {},
      secondary: [],
      availableTiers: [],
    });
  },
  startCheckoutSession: async () => {
    return Result.success({ url: `/` });
  },
  securityEventsFeed: async () => {
    return Result.success([]);
  },
  toggleChildKeychain: async () => {
    return Result.success({ success: true });
  },
  upsertBlockRule: async () => {
    return Result.success(``);
  },
  verifySignupEmail: async () => {
    return Result.success({ token: ``, adminId: `` });
  },
  requestPublicKeychain: async () => {
    return Result.success({ success: true });
  },
  updateIOSDevice: async () => {
    return Result.success({ success: true });
  },
};

export default noopClient;
