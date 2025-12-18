import DashboardClient from '@shared/pairql/dashboard';
import type { PqlError } from '@shared/pairql';
import type { ClientAuth } from '@shared/pairql/src/dashboard';

const apiEndpoint = getApiEndpoint();

export const liveClient = new DashboardClient(
  apiEndpoint,
  createPrepareRequest(apiEndpoint),
);

function createPrepareRequest(
  endpoint: string,
): (init: RequestInit, auth: ClientAuth) => PqlError | null {
  return (init: RequestInit, auth: ClientAuth): PqlError | null => {
    const headers = init.headers as Record<string, string>;

    if (!endpoint.startsWith(`https://api.`)) {
      headers[`X-DashboardUrl`] = window.location.origin;
    }

    if (auth === `parent`) {
      const token =
        localStorage.getItem(`admin_token`) ?? sessionStorage.getItem(`admin_token`);
      if (!token) {
        return {
          isPqlError: true,
          id: `10569a9f`,
          type: `loggedOut`,
          debugMessage: `No parent token found`,
        };
      }
      headers[`X-AdminToken`] = token;
    }

    return null;
  };
}

function getApiEndpoint(): string {
  const endpoint = import.meta.env.VITE_API_ENDPOINT;
  if (!endpoint) {
    throw new Error(`VITE_API_ENDPOINT environment variable is not set`);
  }
  return endpoint;
}

export type ApiClient = Omit<
  typeof liveClient,
  `endpoint` | `domain` | `prepareRequest` | `query`
>;

// throwing client

export const throwingClient: ApiClient = {
  childActivitySummaries: () => {
    throw new Error(`ApiClient.childActivitySummaries() not implemented`);
  },
  combinedUsersActivityFeed: () => {
    throw new Error(`ApiClient.combinedUsersActivityFeed() not implemented`);
  },
  confirmPendingNotificationMethod: () => {
    throw new Error(`ApiClient.confirmPendingNotificationMethod() not implemented`);
  },
  createPendingAppConnection: () => {
    throw new Error(`ApiClient.createPendingAppConnection() not implemented`);
  },
  createPendingNotificationMethod: () => {
    throw new Error(`ApiClient.createPendingNotificationMethod() not implemented`);
  },
  dashboardWidgets: () => {
    throw new Error(`ApiClient.dashboardWidgets() not implemented`);
  },
  decideFilterSuspensionRequest: () => {
    throw new Error(`ApiClient.decideFilterSuspensionRequest() not implemented`);
  },
  deleteActivityItems: () => {
    throw new Error(`ApiClient.deleteActivityItems() not implemented`);
  },
  deleteEntity: () => {
    throw new Error(`ApiClient.deleteEntity() not implemented`);
  },
  familyActivitySummaries: () => {
    throw new Error(`ApiClient.familyActivitySummaries() not implemented`);
  },
  flagActivityItems: () => {
    throw new Error(`ApiClient.flagActivityItems() not implemented`);
  },
  getAdmin: () => {
    throw new Error(`ApiClient.getAdmin() not implemented`);
  },
  getAdminKeychain: () => {
    throw new Error(`ApiClient.getAdminKeychain() not implemented`);
  },
  getAdminKeychains: () => {
    throw new Error(`ApiClient.getAdminKeychains() not implemented`);
  },
  getDevice: () => {
    throw new Error(`ApiClient.getDevice() not implemented`);
  },
  getDevices: () => {
    throw new Error(`ApiClient.getDevices() not implemented`);
  },
  getIdentifiedApps: () => {
    throw new Error(`ApiClient.getIdentifiedApps() not implemented`);
  },
  getIOSDevice: () => {
    throw new Error(`ApiClient.getIOSDevice() not implemented`);
  },
  getSelectableKeychains: () => {
    throw new Error(`ApiClient.getSelectableKeychains() not implemented`);
  },
  getSuspendFilterRequest: () => {
    throw new Error(`ApiClient.getSuspendFilterRequest() not implemented`);
  },
  getUnlockRequest: () => {
    throw new Error(`ApiClient.getUnlockRequest() not implemented`);
  },
  getUnlockRequests: () => {
    throw new Error(`ApiClient.getUnlockRequests() not implemented`);
  },
  getUser: () => {
    throw new Error(`ApiClient.getUser() not implemented`);
  },
  getUsers: () => {
    throw new Error(`ApiClient.getUsers() not implemented`);
  },
  getUserUnlockRequests: () => {
    throw new Error(`ApiClient.getUserUnlockRequests() not implemented`);
  },
  handleCheckoutCancel: () => {
    throw new Error(`ApiClient.handleCheckoutCancel() not implemented`);
  },
  handleCheckoutSuccess: () => {
    throw new Error(`ApiClient.handleCheckoutSuccess() not implemented`);
  },
  iOSDevices: () => {
    throw new Error(`ApiClient.iOSDevices() not implemented`);
  },
  latestAppVersions: () => {
    throw new Error(`ApiClient.latestAppVersions() not implemented`);
  },
  logEvent: () => {
    throw new Error(`ApiClient.logEvent() not implemented`);
  },
  login: () => {
    throw new Error(`ApiClient.login() not implemented`);
  },
  loginMagicLink: () => {
    throw new Error(`ApiClient.loginMagicLink() not implemented`);
  },
  requestMagicLink: () => {
    throw new Error(`ApiClient.requestMagicLink() not implemented`);
  },
  requestPublicKeychain: () => {
    throw new Error(`ApiClient.requestPublicKeychain() not implemented`);
  },
  resetPassword: () => {
    throw new Error(`ApiClient.resetPassword() not implemented`);
  },
  saveConferenceEmail: () => {
    throw new Error(`ApiClient.saveConferenceEmail() not implemented`);
  },
  saveDevice: () => {
    throw new Error(`ApiClient.saveDevice() not implemented`);
  },
  saveKey: () => {
    throw new Error(`ApiClient.saveKey() not implemented`);
  },
  saveKeychain: () => {
    throw new Error(`ApiClient.saveKeychain() not implemented`);
  },
  saveNotification: () => {
    throw new Error(`ApiClient.saveNotification() not implemented`);
  },
  saveUser: () => {
    throw new Error(`ApiClient.saveUser() not implemented`);
  },
  securityEventsFeed: () => {
    throw new Error(`ApiClient.securityEventsFeed() not implemented`);
  },
  sendPasswordResetEmail: () => {
    throw new Error(`ApiClient.sendPasswordResetEmail() not implemented`);
  },
  signup: () => {
    throw new Error(`ApiClient.signup() not implemented`);
  },
  stripeUrl: () => {
    throw new Error(`ApiClient.stripeUrl() not implemented`);
  },
  toggleChildKeychain: () => {
    throw new Error(`ApiClient.toggleChildKeychain() not implemented`);
  },
  updateIOSDevice: () => {
    throw new Error(`ApiClient.updateIOSDevice() not implemented`);
  },
  updateUnlockRequest: () => {
    throw new Error(`ApiClient.updateUnlockRequest() not implemented`);
  },
  upsertBlockRule: () => {
    throw new Error(`ApiClient.upsertBlockRule() not implemented`);
  },
  userActivityFeed: () => {
    throw new Error(`ApiClient.userActivityFeed() not implemented`);
  },
  verifySignupEmail: () => {
    throw new Error(`ApiClient.verifySignupEmail() not implemented`);
  },
};
