import { Result } from '@dash/types';
import type { ApiClient } from './client';

const noopClient: ApiClient = {
  confirmPendingNotificationMethod: async () => {
    return Result.success({ success: true });
  },
  createBillingPortalSession: async () => {
    return Result.success({ url: `` });
  },
  createPendingAppConnection: async () => {
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
  getAdmin: async () => {
    return Result.success({
      id: ``,
      email: ``,
      subscriptionStatus: `active`,
      notifications: [],
      verifiedNotificationMethods: [],
    });
  },
  getAdminKeychain: async () => {
    return Result.success({
      summary: {
        id: ``,
        authorId: ``,
        name: ``,
        description: ``,
        isPublic: false,
        numKeys: 0,
      },
      keys: [],
    });
  },
  getAdminKeychains: async () => {
    return Result.success([]);
  },
  getDashboardWidgets: async () => {
    return Result.success({
      users: [],
      userActivitySummaries: [],
      unlockRequests: [],
      recentScreenshots: [],
      numAdminNotifications: 0,
    });
  },
  getIdentifiedApps: async () => {
    return Result.success([]);
  },
  getSelectableKeychains: async () => {
    return Result.success({ own: [], public: [] });
  },
  getSuspendFilterRequest: async () => {
    return Result.success({
      id: ``,
      deviceId: ``,
      userName: ``,
      requestedDurationInSeconds: 0,
      requestComment: ``,
      status: `rejected`,
      createdAt: new Date().toISOString(),
    });
  },
  getUnlockRequest: async () => {
    return Result.success({
      id: ``,
      userId: ``,
      userName: ``,
      status: `rejected`,
      url: ``,
      domain: ``,
      ipAddress: ``,
      requestComment: ``,
      appName: ``,
      appSlug: ``,
      appBundleId: ``,
      appCategories: [],
      requestProtocol: ``,
      createdAt: new Date().toISOString(),
    });
  },
  getUnlockRequests: async () => {
    return Result.success([]);
  },
  getUser: async () => {
    return Result.success({
      id: ``,
      name: ``,
      keyloggingEnabled: false,
      screenshotsEnabled: false,
      screenshotsResolution: 1000,
      screenshotsFrequency: 90,
      keychains: [],
      devices: [],
      createdAt: new Date().toISOString(),
    });
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
  hollandTalkSubscription: async () => {
    return Result.success({ success: true });
  },
  userActivityFeed: async () => {
    return Result.success({ numDeleted: 0, userName: ``, items: [] });
  },
  combinedUsersActivityFeed: async () => {
    return Result.success([]);
  },
  userActivitySummaries: async () => {
    return Result.success({ userName: ``, days: [] });
  },
  combinedUsersActivitySummaries: async () => {
    return Result.success([]);
  },
  getUsers: async () => {
    return Result.success([]);
  },
  getDevices: async () => {
    return Result.success([]);
  },
  latestAppVersions: async () => {
    return Result.success({
      stable: ``,
      beta: ``,
      canary: ``,
    });
  },
  getUserUnlockRequests: async () => {
    return Result.success([]);
  },
  login: async () => {
    return Result.success({ token: ``, adminId: `` });
  },
  loginMagicLink: async () => {
    return Result.success({ token: ``, adminId: `` });
  },
  requestMagicLink: async () => {
    return Result.success({ success: true });
  },
  resetPassword: async () => {
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
    return Result.success({ success: true });
  },
  updateSuspendFilterRequest: async () => {
    return Result.success({ success: true });
  },
  updateUnlockRequest: async () => {
    return Result.success({ success: true });
  },
  verifySignupEmail: async () => {
    return Result.success({ token: ``, adminId: `` });
  },
};

export default noopClient;
