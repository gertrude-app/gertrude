// auto-generated, do not edit
import * as Pql from './pairs';

export interface ApiClient {
  deleteEntity: typeof Pql.DeleteEntity.fetch;
  saveKeychain: typeof Pql.SaveKeychain.fetch;
  signup: typeof Pql.Signup.fetch;
  getUserActivityDay: typeof Pql.GetUserActivityDay.fetch;
  saveNotification: typeof Pql.SaveNotification_v0.fetch;
  createBillingPortalSession: typeof Pql.CreateBillingPortalSession.fetch;
  getSuspendFilterRequest: typeof Pql.GetSuspendFilterRequest.fetch;
  updateSuspendFilterRequest: typeof Pql.UpdateSuspendFilterRequest.fetch;
  confirmPendingNotificationMethod: typeof Pql.ConfirmPendingNotificationMethod.fetch;
  getUnlockRequests: typeof Pql.GetUnlockRequests.fetch;
  getCheckoutUrl: typeof Pql.GetCheckoutUrl.fetch;
  getUser: typeof Pql.GetUser.fetch;
  getAdminKeychain: typeof Pql.GetAdminKeychain.fetch;
  getUserActivityDays: typeof Pql.GetUserActivityDays.fetch;
  joinWaitlist: typeof Pql.JoinWaitlist.fetch;
  getUsers: typeof Pql.GetUsers.fetch;
  handleCheckoutCancel: typeof Pql.HandleCheckoutCancel.fetch;
  saveUser: typeof Pql.SaveUser.fetch;
  getUserUnlockRequests: typeof Pql.GetUserUnlockRequests.fetch;
  getDashboardWidgets: typeof Pql.GetDashboardWidgets.fetch;
  deleteActivityItems: typeof Pql.DeleteActivityItems.fetch;
  getIdentifiedApps: typeof Pql.GetIdentifiedApps.fetch;
  requestMagicLink: typeof Pql.RequestMagicLink.fetch;
  updateUnlockRequest: typeof Pql.UpdateUnlockRequest.fetch;
  verifySignupEmail: typeof Pql.VerifySignupEmail.fetch;
  loginMagicLink: typeof Pql.LoginMagicLink.fetch;
  saveKey: typeof Pql.SaveKey.fetch;
  handleCheckoutSuccess: typeof Pql.HandleCheckoutSuccess.fetch;
  getAdminKeychains: typeof Pql.GetAdminKeychains.fetch;
  createPendingNotificationMethod: typeof Pql.CreatePendingNotificationMethod.fetch;
  getSelectableKeychains: typeof Pql.GetSelectableKeychains.fetch;
  getAdmin: typeof Pql.GetAdmin.fetch;
  getUnlockRequest: typeof Pql.GetUnlockRequest.fetch;
  createPendingAppConnection: typeof Pql.CreatePendingAppConnection.fetch;
  allowingSignups: typeof Pql.AllowingSignups.fetch;
}

const liveClient: ApiClient = {
  deleteEntity: Pql.DeleteEntity.fetch,
  saveKeychain: Pql.SaveKeychain.fetch,
  signup: Pql.Signup.fetch,
  getUserActivityDay: Pql.GetUserActivityDay.fetch,
  saveNotification: Pql.SaveNotification_v0.fetch,
  createBillingPortalSession: Pql.CreateBillingPortalSession.fetch,
  getSuspendFilterRequest: Pql.GetSuspendFilterRequest.fetch,
  updateSuspendFilterRequest: Pql.UpdateSuspendFilterRequest.fetch,
  confirmPendingNotificationMethod: Pql.ConfirmPendingNotificationMethod.fetch,
  getUnlockRequests: Pql.GetUnlockRequests.fetch,
  getCheckoutUrl: Pql.GetCheckoutUrl.fetch,
  getUser: Pql.GetUser.fetch,
  getAdminKeychain: Pql.GetAdminKeychain.fetch,
  getUserActivityDays: Pql.GetUserActivityDays.fetch,
  joinWaitlist: Pql.JoinWaitlist.fetch,
  getUsers: Pql.GetUsers.fetch,
  handleCheckoutCancel: Pql.HandleCheckoutCancel.fetch,
  saveUser: Pql.SaveUser.fetch,
  getUserUnlockRequests: Pql.GetUserUnlockRequests.fetch,
  getDashboardWidgets: Pql.GetDashboardWidgets.fetch,
  deleteActivityItems: Pql.DeleteActivityItems.fetch,
  getIdentifiedApps: Pql.GetIdentifiedApps.fetch,
  requestMagicLink: Pql.RequestMagicLink.fetch,
  updateUnlockRequest: Pql.UpdateUnlockRequest.fetch,
  verifySignupEmail: Pql.VerifySignupEmail.fetch,
  loginMagicLink: Pql.LoginMagicLink.fetch,
  saveKey: Pql.SaveKey.fetch,
  handleCheckoutSuccess: Pql.HandleCheckoutSuccess.fetch,
  getAdminKeychains: Pql.GetAdminKeychains.fetch,
  createPendingNotificationMethod: Pql.CreatePendingNotificationMethod.fetch,
  getSelectableKeychains: Pql.GetSelectableKeychains.fetch,
  getAdmin: Pql.GetAdmin.fetch,
  getUnlockRequest: Pql.GetUnlockRequest.fetch,
  createPendingAppConnection: Pql.CreatePendingAppConnection.fetch,
  allowingSignups: Pql.AllowingSignups.fetch,
};

export const throwingClient: ApiClient = {
  deleteEntity: () => {
    throw new Error('Apiclient.deleteEntity() not implemented');
  },
  saveKeychain: () => {
    throw new Error('Apiclient.saveKeychain() not implemented');
  },
  signup: () => {
    throw new Error('Apiclient.signup() not implemented');
  },
  getUserActivityDay: () => {
    throw new Error('Apiclient.getUserActivityDay() not implemented');
  },
  saveNotification: () => {
    throw new Error('Apiclient.saveNotification() not implemented');
  },
  createBillingPortalSession: () => {
    throw new Error('Apiclient.createBillingPortalSession() not implemented');
  },
  getSuspendFilterRequest: () => {
    throw new Error('Apiclient.getSuspendFilterRequest() not implemented');
  },
  updateSuspendFilterRequest: () => {
    throw new Error('Apiclient.updateSuspendFilterRequest() not implemented');
  },
  confirmPendingNotificationMethod: () => {
    throw new Error('Apiclient.confirmPendingNotificationMethod() not implemented');
  },
  getUnlockRequests: () => {
    throw new Error('Apiclient.getUnlockRequests() not implemented');
  },
  getCheckoutUrl: () => {
    throw new Error('Apiclient.getCheckoutUrl() not implemented');
  },
  getUser: () => {
    throw new Error('Apiclient.getUser() not implemented');
  },
  getAdminKeychain: () => {
    throw new Error('Apiclient.getAdminKeychain() not implemented');
  },
  getUserActivityDays: () => {
    throw new Error('Apiclient.getUserActivityDays() not implemented');
  },
  joinWaitlist: () => {
    throw new Error('Apiclient.joinWaitlist() not implemented');
  },
  getUsers: () => {
    throw new Error('Apiclient.getUsers() not implemented');
  },
  handleCheckoutCancel: () => {
    throw new Error('Apiclient.handleCheckoutCancel() not implemented');
  },
  saveUser: () => {
    throw new Error('Apiclient.saveUser() not implemented');
  },
  getUserUnlockRequests: () => {
    throw new Error('Apiclient.getUserUnlockRequests() not implemented');
  },
  getDashboardWidgets: () => {
    throw new Error('Apiclient.getDashboardWidgets() not implemented');
  },
  deleteActivityItems: () => {
    throw new Error('Apiclient.deleteActivityItems() not implemented');
  },
  getIdentifiedApps: () => {
    throw new Error('Apiclient.getIdentifiedApps() not implemented');
  },
  requestMagicLink: () => {
    throw new Error('Apiclient.requestMagicLink() not implemented');
  },
  updateUnlockRequest: () => {
    throw new Error('Apiclient.updateUnlockRequest() not implemented');
  },
  verifySignupEmail: () => {
    throw new Error('Apiclient.verifySignupEmail() not implemented');
  },
  loginMagicLink: () => {
    throw new Error('Apiclient.loginMagicLink() not implemented');
  },
  saveKey: () => {
    throw new Error('Apiclient.saveKey() not implemented');
  },
  handleCheckoutSuccess: () => {
    throw new Error('Apiclient.handleCheckoutSuccess() not implemented');
  },
  getAdminKeychains: () => {
    throw new Error('Apiclient.getAdminKeychains() not implemented');
  },
  createPendingNotificationMethod: () => {
    throw new Error('Apiclient.createPendingNotificationMethod() not implemented');
  },
  getSelectableKeychains: () => {
    throw new Error('Apiclient.getSelectableKeychains() not implemented');
  },
  getAdmin: () => {
    throw new Error('Apiclient.getAdmin() not implemented');
  },
  getUnlockRequest: () => {
    throw new Error('Apiclient.getUnlockRequest() not implemented');
  },
  createPendingAppConnection: () => {
    throw new Error('Apiclient.createPendingAppConnection() not implemented');
  },
  allowingSignups: () => {
    throw new Error('Apiclient.allowingSignups() not implemented');
  },
};

export default liveClient;
