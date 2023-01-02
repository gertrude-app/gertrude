import type { ApiClient } from './client';
import Result from '../lib/Result';
import { RequestStatus } from './shared';

export const noopClient: ApiClient = {
  deleteEntity: async () => {
    return Result.success({ success: true });
  },
  saveKeychain: async () => {
    return Result.success({ success: true });
  },
  signup: async () => {
    return Result.success({});
  },
  getUserActivityDay: async () => {
    return Result.success({ userName: ``, items: [] });
  },
  saveNotification: async () => {
    return Result.success({ id: `` });
  },
  createBillingPortalSession: async () => {
    return Result.success({ url: `` });
  },
  getSuspendFilterRequest: async () => {
    return Result.success({
      id: ``,
      deviceId: ``,
      userName: ``,
      requestedDurationInSeconds: 0,
      requestComment: ``,
      status: RequestStatus.rejected,
      createdAt: new Date().toISOString(),
    });
  },
  updateSuspendFilterRequest: async () => {
    return Result.success({ success: true });
  },
  confirmPendingNotificationMethod: async () => {
    return Result.success({ success: true });
  },
  getUnlockRequests: async () => {
    return Result.success([]);
  },
  getCheckoutUrl: async () => {
    return Result.success({});
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
  getUserActivityDays: async () => {
    return Result.success({ userName: ``, days: [] });
  },
  getAdminKeychain: async () => {
    throw new Error(`Not implemented`);
  },
  joinWaitlist: async () => {
    return Result.success({ success: true });
  },
  getUsers: async () => {
    return Result.success([]);
  },
  handleCheckoutCancel: async () => {
    return Result.success({ success: true });
  },
  saveUser: async () => {
    return Result.success({ success: true });
  },
  getUserUnlockRequests: async () => {
    return Result.success([]);
  },
  getDashboardWidgets: async () => {
    return Result.success({
      users: [],
      userActivitySummaries: [],
      unlockRequests: [],
      recentScreenshots: [],
    });
  },
  deleteActivityItems: async () => {
    return Result.success({ success: true });
  },
  getIdentifiedApps: async () => {
    return Result.success([]);
  },
  requestMagicLink: async () => {
    return Result.success({ success: true });
  },
  updateUnlockRequest: async () => {
    return Result.success({ success: true });
  },
  verifySignupEmail: async () => {
    return Result.success({ adminId: `` });
  },
  loginMagicLink: async () => {
    return Result.success({ token: ``, adminId: `` });
  },
  saveKey: async () => {
    return Result.success({ success: true });
  },
  handleCheckoutSuccess: async () => {
    return Result.success({ token: ``, adminId: `` });
  },
  getAdminKeychains: async () => {
    return Result.success([]);
  },
  createPendingNotificationMethod: async () => {
    return Result.success({ methodId: `` });
  },
  getSelectableKeychains: async () => {
    return Result.success({ own: [], public: [] });
  },
  getAdmin: async () => {
    return Result.success({
      id: ``,
      email: ``,
      notifications: [],
      verifiedNotificationMethods: [],
    });
  },
  getUnlockRequest: async () => {
    return Result.success({
      id: ``,
      userId: ``,
      userName: ``,
      status: RequestStatus.rejected,
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
  createPendingAppConnection: async () => {
    return Result.success({ code: 0 });
  },
  allowingSignups: async () => {
    return Result.success({ success: true });
  },
};

export default noopClient;
