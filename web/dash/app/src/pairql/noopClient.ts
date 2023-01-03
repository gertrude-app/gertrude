import { RequestStatus, Result } from '@dash/types';
import type { ApiClient } from './client';

const noopClient: ApiClient = {
  allowingSignups: async () => {
    return Result.success({ success: true });
  },
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
      notifications: [],
      verifiedNotificationMethods: [],
    });
  },
  getAdminKeychain: async () => {
    return Result.success({ success: true });
  },
  getAdminKeychains: async () => {
    return Result.success([]);
  },
  getCheckoutUrl: async () => {
    return Result.success({});
  },
  getDashboardWidgets: async () => {
    return Result.success({
      users: [],
      userActivitySummaries: [],
      unlockRequests: [],
      recentScreenshots: [],
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
      status: RequestStatus.rejected,
      createdAt: new Date().toISOString(),
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
  getUserActivityDay: async () => {
    return Result.success({ userName: ``, items: [] });
  },
  getUserActivityDays: async () => {
    return Result.success({ userName: ``, days: [] });
  },
  getUsers: async () => {
    return Result.success([]);
  },
  getUserUnlockRequests: async () => {
    return Result.success([]);
  },
  handleCheckoutCancel: async () => {
    return Result.success({ success: true });
  },
  handleCheckoutSuccess: async () => {
    return Result.success({ token: ``, adminId: `` });
  },
  joinWaitlist: async () => {
    return Result.success({ success: true });
  },
  loginMagicLink: async () => {
    return Result.success({ token: ``, adminId: `` });
  },
  requestMagicLink: async () => {
    return Result.success({ success: true });
  },
  saveKey: async () => {
    return Result.success({ success: true });
  },
  saveKeychain: async () => {
    return Result.success({ success: true });
  },
  saveNotification: async () => {
    return Result.success({ id: `` });
  },
  saveUser: async () => {
    return Result.success({ success: true });
  },
  signup: async () => {
    return Result.success({});
  },
  updateSuspendFilterRequest: async () => {
    return Result.success({ success: true });
  },
  updateUnlockRequest: async () => {
    return Result.success({ success: true });
  },
  verifySignupEmail: async () => {
    return Result.success({ adminId: `` });
  },
};

export default noopClient;
