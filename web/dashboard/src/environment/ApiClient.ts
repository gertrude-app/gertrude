import { RequestStatus, SubscriptionStatus } from '@dashboard/types/GraphQL';
import Result from '../api/Result';
import * as empty from '../redux/empty';
import * as admin from '../api/admin';
import * as users from '../api/users';
import * as signup from '../api/signup';
import * as keychains from '../api/keychains';
import * as requests from '../api/requests';
import * as apps from '../api/apps';
import * as dashboard from '../api/dashboard';

export interface ApiClient {
  admin: typeof admin;
  apps: typeof apps;
  dashboard: typeof dashboard;
  keychains: typeof keychains;
  signup: typeof signup;
  requests: typeof requests;
  users: typeof users;
}

export const liveApiClient: ApiClient = {
  admin,
  apps,
  dashboard,
  keychains,
  signup,
  requests,
  users,
};

export const throwingApiClient: ApiClient = {
  apps: {
    getIdentifiedApps: () => {
      throw new Error(`ApiClient.apps.getIdentifiedApps not implemented`);
    },
  },
  admin: {
    login: () => {
      throw new Error(`ApiClient.admin.login() not implemented.`);
    },
    requestMagicLink: () => {
      throw new Error(`ApiClient.admin.requestMagicLink() not implemented.`);
    },
    loginFromMagicLink: () => {
      throw new Error(`ApiClient.admin.loginFromMagicLink() not implemented.`);
    },
    getAdmin: () => {
      throw new Error(`ApiClient.admin.getAdmin() not implemented.`);
    },
    deleteNotification: () => {
      throw new Error(`ApiClient.admin.deleteNotification() not implemented.`);
    },
    deleteNotificationMethod: () => {
      throw new Error(`ApiClient.admin.deleteNotificationMethod() not implemented.`);
    },
    upsertNotification: () => {
      throw new Error(`ApiClient.admin.upsertNotification() not implemented.`);
    },
    createPendingNotificationMethod: () => {
      throw new Error(
        `ApiClient.admin.createPendingNotificationMethod() not implemented.`,
      );
    },
    confirmPendingNotificationMethod: () => {
      throw new Error(
        `ApiClient.admin.confirmPendingNotificationMethod() not implemented.`,
      );
    },
    createBillingPortalSession: () => {
      throw new Error(`ApiClient.admin.createBillingPortalSession() not implemented.`);
    },
  },
  dashboard: {
    getWidgets: () => {
      throw new Error(`ApiClient.dashboard.getWidgets() not implemented.`);
    },
  },
  keychains: {
    deleteKeychain: () => {
      throw new Error(`ApiClient.keychains.deleteKeychain() not implemented.`);
    },
    deleteKeyRecord: () => {
      throw new Error(`ApiClient.keychains.deleteKeyRecord() not implemented.`);
    },
    listAdminKeychains: () => {
      throw new Error(`ApiClient.keychains.listAdminKeychains() not implemented.`);
    },
    getAdminKeychain: () => {
      throw new Error(`ApiClient.keychains.getAdminKeychain() not implemented.`);
    },
    upsertKeychain: () => {
      throw new Error(`ApiClient.keychains.upsertKeychain() not implemented.`);
    },
    upsertKeyRecord: () => {
      throw new Error(`ApiClient.keychains.upsertKeyRecord() not implemented.`);
    },
    getSelectableKeychains: () => {
      throw new Error(`ApiClient.keychains.getSelectableKeychains() not implemented.`);
    },
  },
  users: {
    list: () => {
      throw new Error(`ApiClient.users.list() not implemented.`);
    },
    getUser: () => {
      throw new Error(`ApiClient.users.getUser() not implemented.`);
    },
    upsertUser: () => {
      throw new Error(`ApiClient.users.upsertUser() not implemented.`);
    },
    setUserKeychains: () => {
      throw new Error(`ApiClient.users.setUserKeychains() not implemented.`);
    },
    getActivityOverview: () => {
      throw new Error(`ApiClient.users.getActivityOverview() not implemented.`);
    },
    getActivityDay: () => {
      throw new Error(`ApiClient.users.getActivityDay() not implemented.`);
    },
    deleteActivityItems: () => {
      throw new Error(`ApiClient.users.deleteActivityItems() not implemented.`);
    },
    deleteDevice: () => {
      throw new Error(`ApiClient.users.deleteDevice() not implemented.`);
    },
    deleteUser: () => {
      throw new Error(`ApiClient.users.deleteUser() not implemented.`);
    },
    createPendingAppConnection: () => {
      throw new Error(`ApiClient.users.createPendingUserConnection() not implemented.`);
    },
  },
  requests: {
    getSuspendFilterRequest: () => {
      throw new Error(`ApiClient.requests.getSuspendFilterRequest() not implemented.`);
    },
    updateSuspendFilterRequest: () => {
      throw new Error(`ApiClient.requests.updateSuspendFilterRequest() not implemented.`);
    },
  },
  signup: {
    joinWaitlist: () => {
      throw new Error(`ApiClient.signup.joinWaitlist() not implemented.`);
    },
    allowingSignups: () => {
      throw new Error(`ApiClient.signup.allowingSignups() not implemented.`);
    },
    initiateSignup: () => {
      throw new Error(`ApiClient.signup.sendVerificationEmail() not implemented.`);
    },
    createSignupPaymentUrl: () => {
      throw new Error(`ApiClient.signup.createSignupPaymentUrl() not implemented.`);
    },
    handleSignupPaymentCanceled: () => {
      throw new Error(`ApiClient.signup.handleSignupPaymentCanceled() not implemented.`);
    },
    handleSignupPaymentSuccess: () => {
      throw new Error(`ApiClient.signup.handleSignupPaymentSuccess() not implemented.`);
    },
    verifySignupEmail: () => {
      throw new Error(`ApiClient.signup.verifySignupEmail() not implemented.`);
    },
  },
};

export const noopApiClient: ApiClient = {
  apps: {
    getIdentifiedApps: async () => {
      return Result.success([]);
    },
  },
  admin: {
    login: async () => {
      return Result.success({ id: ``, token: `` });
    },
    requestMagicLink: async () => {
      return Result.success(true);
    },
    loginFromMagicLink: async () => {
      return Result.success({ id: ``, token: `` });
    },
    getAdmin: async () => {
      return Result.success({
        __typename: `Admin`,
        email: ``,
        subscriptionStatus: SubscriptionStatus.active,
        notifications: [],
        verifiedNotificationMethods: [],
      });
    },
    deleteNotification: async () => {
      return Result.success(true);
    },
    deleteNotificationMethod: async () => {
      return Result.success(true);
    },
    upsertNotification: async () => {
      return Result.success(``);
    },
    createPendingNotificationMethod: async () => {
      return Result.success(``);
    },
    confirmPendingNotificationMethod: async () => {
      return Result.success(true);
    },
    createBillingPortalSession: async () => {
      return Result.success(``);
    },
  },
  dashboard: {
    getWidgets: async () => {
      return Result.success({
        unlockRequests: [],
        users: [],
        userActivity: [],
        userScreenshots: [],
      });
    },
  },
  keychains: {
    deleteKeychain: async () => {
      return Result.success(true);
    },
    deleteKeyRecord: async () => {
      return Result.success(true);
    },
    listAdminKeychains: async () => {
      return Result.success([[], []]);
    },
    getAdminKeychain: async () => {
      return Result.success([empty.keychain(``, ``), []]);
    },
    upsertKeychain: async () => {
      return Result.true();
    },
    upsertKeyRecord: async () => {
      return Result.true();
    },
    getSelectableKeychains: async () => {
      return Result.success({ own: [], public: [] });
    },
  },
  users: {
    list: async () => {
      return Result.success([]);
    },
    getUser: async () => {
      return Result.success(empty.user());
    },
    upsertUser: async () => {
      return Result.success(``);
    },
    setUserKeychains: async () => {
      return Result.success(true);
    },
    getActivityOverview: async () => {
      return Result.success({ user: { __typename: `User`, name: `` }, counts: [] });
    },
    getActivityDay: async () => {
      return Result.success({ counts: [], items: [] });
    },
    deleteActivityItems: async () => {
      return Result.success(true);
    },
    deleteDevice: async () => {
      return Result.success(true);
    },
    deleteUser: async () => {
      return Result.success(true);
    },
    createPendingAppConnection: async () => {
      return Result.success(0);
    },
  },
  requests: {
    getSuspendFilterRequest: async () => {
      return Result.success({
        id: ``,
        deviceId: ``,
        name: ``,
        requestedDurationInSeconds: 0,
        userName: ``,
        status: RequestStatus.pending,
        createdAt: ``,
      });
    },
    updateSuspendFilterRequest: async () => {
      return Result.true();
    },
  },
  signup: {
    joinWaitlist: async () => {
      return Result.true();
    },
    allowingSignups: async () => {
      return Result.true();
    },
    initiateSignup: async () => {
      return Result.success(null);
    },
    createSignupPaymentUrl: async () => {
      return Result.success(``);
    },
    handleSignupPaymentCanceled: async () => {
      return Result.true();
    },
    handleSignupPaymentSuccess: async () => {
      return Result.success({ id: ``, token: `` });
    },
    verifySignupEmail: async () => {
      return Result.success(``);
    },
  },
};
