// auto-generated, do not edit
import { ClientAuth } from '@dash/pairs';
import type * as T from '@dash/pairs';
import { query } from './query';

export const liveClient = {
  allowingSignups(
    input: T.AllowingSignups.Input,
  ): Promise<T.Result<T.AllowingSignups.Output>> {
    return query<T.AllowingSignups.Input, T.AllowingSignups.Output>(
      input,
      ClientAuth.none,
      `AllowingSignups`,
    );
  },

  confirmPendingNotificationMethod(
    input: T.ConfirmPendingNotificationMethod.Input,
  ): Promise<T.Result<T.ConfirmPendingNotificationMethod.Output>> {
    return query<
      T.ConfirmPendingNotificationMethod.Input,
      T.ConfirmPendingNotificationMethod.Output
    >(input, ClientAuth.admin, `ConfirmPendingNotificationMethod`);
  },

  createBillingPortalSession(
    input: T.CreateBillingPortalSession.Input,
  ): Promise<T.Result<T.CreateBillingPortalSession.Output>> {
    return query<T.CreateBillingPortalSession.Input, T.CreateBillingPortalSession.Output>(
      input,
      ClientAuth.admin,
      `CreateBillingPortalSession`,
    );
  },

  createPendingAppConnection(
    input: T.CreatePendingAppConnection.Input,
  ): Promise<T.Result<T.CreatePendingAppConnection.Output>> {
    return query<T.CreatePendingAppConnection.Input, T.CreatePendingAppConnection.Output>(
      input,
      ClientAuth.admin,
      `CreatePendingAppConnection`,
    );
  },

  createPendingNotificationMethod(
    input: T.CreatePendingNotificationMethod.Input,
  ): Promise<T.Result<T.CreatePendingNotificationMethod.Output>> {
    return query<
      T.CreatePendingNotificationMethod.Input,
      T.CreatePendingNotificationMethod.Output
    >(input, ClientAuth.admin, `CreatePendingNotificationMethod`);
  },

  deleteActivityItems(
    input: T.DeleteActivityItems.Input,
  ): Promise<T.Result<T.DeleteActivityItems.Output>> {
    return query<T.DeleteActivityItems.Input, T.DeleteActivityItems.Output>(
      input,
      ClientAuth.admin,
      `DeleteActivityItems`,
    );
  },

  deleteEntity(input: T.DeleteEntity.Input): Promise<T.Result<T.DeleteEntity.Output>> {
    return query<T.DeleteEntity.Input, T.DeleteEntity.Output>(
      input,
      ClientAuth.admin,
      `DeleteEntity`,
    );
  },

  getAdmin(input: T.GetAdmin.Input): Promise<T.Result<T.GetAdmin.Output>> {
    return query<T.GetAdmin.Input, T.GetAdmin.Output>(
      input,
      ClientAuth.admin,
      `GetAdmin`,
    );
  },

  getAdminKeychain(
    input: T.GetAdminKeychain.Input,
  ): Promise<T.Result<T.GetAdminKeychain.Output>> {
    return query<T.GetAdminKeychain.Input, T.GetAdminKeychain.Output>(
      input,
      ClientAuth.admin,
      `GetAdminKeychain`,
    );
  },

  getAdminKeychains(
    input: T.GetAdminKeychains.Input,
  ): Promise<T.Result<T.GetAdminKeychains.Output>> {
    return query<T.GetAdminKeychains.Input, T.GetAdminKeychains.Output>(
      input,
      ClientAuth.admin,
      `GetAdminKeychains`,
    );
  },

  getCheckoutUrl(
    input: T.GetCheckoutUrl.Input,
  ): Promise<T.Result<T.GetCheckoutUrl.Output>> {
    return query<T.GetCheckoutUrl.Input, T.GetCheckoutUrl.Output>(
      input,
      ClientAuth.admin,
      `GetCheckoutUrl`,
    );
  },

  getDashboardWidgets(
    input: T.GetDashboardWidgets.Input,
  ): Promise<T.Result<T.GetDashboardWidgets.Output>> {
    return query<T.GetDashboardWidgets.Input, T.GetDashboardWidgets.Output>(
      input,
      ClientAuth.admin,
      `GetDashboardWidgets`,
    );
  },

  getIdentifiedApps(
    input: T.GetIdentifiedApps.Input,
  ): Promise<T.Result<T.GetIdentifiedApps.Output>> {
    return query<T.GetIdentifiedApps.Input, T.GetIdentifiedApps.Output>(
      input,
      ClientAuth.admin,
      `GetIdentifiedApps`,
    );
  },

  getSelectableKeychains(
    input: T.GetSelectableKeychains.Input,
  ): Promise<T.Result<T.GetSelectableKeychains.Output>> {
    return query<T.GetSelectableKeychains.Input, T.GetSelectableKeychains.Output>(
      input,
      ClientAuth.admin,
      `GetSelectableKeychains`,
    );
  },

  getSuspendFilterRequest(
    input: T.GetSuspendFilterRequest.Input,
  ): Promise<T.Result<T.GetSuspendFilterRequest.Output>> {
    return query<T.GetSuspendFilterRequest.Input, T.GetSuspendFilterRequest.Output>(
      input,
      ClientAuth.admin,
      `GetSuspendFilterRequest`,
    );
  },

  getUnlockRequest(
    input: T.GetUnlockRequest.Input,
  ): Promise<T.Result<T.GetUnlockRequest.Output>> {
    return query<T.GetUnlockRequest.Input, T.GetUnlockRequest.Output>(
      input,
      ClientAuth.admin,
      `GetUnlockRequest`,
    );
  },

  getUnlockRequests(
    input: T.GetUnlockRequests.Input,
  ): Promise<T.Result<T.GetUnlockRequests.Output>> {
    return query<T.GetUnlockRequests.Input, T.GetUnlockRequests.Output>(
      input,
      ClientAuth.admin,
      `GetUnlockRequests`,
    );
  },

  getUser(input: T.GetUser.Input): Promise<T.Result<T.GetUser.Output>> {
    return query<T.GetUser.Input, T.GetUser.Output>(input, ClientAuth.admin, `GetUser`);
  },

  getUserActivityDay(
    input: T.GetUserActivityDay.Input,
  ): Promise<T.Result<T.GetUserActivityDay.Output>> {
    return query<T.GetUserActivityDay.Input, T.GetUserActivityDay.Output>(
      input,
      ClientAuth.admin,
      `GetUserActivityDay`,
    );
  },

  getUserActivityDays(
    input: T.GetUserActivityDays.Input,
  ): Promise<T.Result<T.GetUserActivityDays.Output>> {
    return query<T.GetUserActivityDays.Input, T.GetUserActivityDays.Output>(
      input,
      ClientAuth.admin,
      `GetUserActivityDays`,
    );
  },

  getUsers(input: T.GetUsers.Input): Promise<T.Result<T.GetUsers.Output>> {
    return query<T.GetUsers.Input, T.GetUsers.Output>(
      input,
      ClientAuth.admin,
      `GetUsers`,
    );
  },

  getUserUnlockRequests(
    input: T.GetUserUnlockRequests.Input,
  ): Promise<T.Result<T.GetUserUnlockRequests.Output>> {
    return query<T.GetUserUnlockRequests.Input, T.GetUserUnlockRequests.Output>(
      input,
      ClientAuth.admin,
      `GetUserUnlockRequests`,
    );
  },

  handleCheckoutCancel(
    input: T.HandleCheckoutCancel.Input,
  ): Promise<T.Result<T.HandleCheckoutCancel.Output>> {
    return query<T.HandleCheckoutCancel.Input, T.HandleCheckoutCancel.Output>(
      input,
      ClientAuth.none,
      `HandleCheckoutCancel`,
    );
  },

  handleCheckoutSuccess(
    input: T.HandleCheckoutSuccess.Input,
  ): Promise<T.Result<T.HandleCheckoutSuccess.Output>> {
    return query<T.HandleCheckoutSuccess.Input, T.HandleCheckoutSuccess.Output>(
      input,
      ClientAuth.none,
      `HandleCheckoutSuccess`,
    );
  },

  joinWaitlist(input: T.JoinWaitlist.Input): Promise<T.Result<T.JoinWaitlist.Output>> {
    return query<T.JoinWaitlist.Input, T.JoinWaitlist.Output>(
      input,
      ClientAuth.none,
      `JoinWaitlist`,
    );
  },

  loginMagicLink(
    input: T.LoginMagicLink.Input,
  ): Promise<T.Result<T.LoginMagicLink.Output>> {
    return query<T.LoginMagicLink.Input, T.LoginMagicLink.Output>(
      input,
      ClientAuth.none,
      `LoginMagicLink`,
    );
  },

  requestMagicLink(
    input: T.RequestMagicLink.Input,
  ): Promise<T.Result<T.RequestMagicLink.Output>> {
    return query<T.RequestMagicLink.Input, T.RequestMagicLink.Output>(
      input,
      ClientAuth.none,
      `RequestMagicLink`,
    );
  },

  saveKey(input: T.SaveKey.Input): Promise<T.Result<T.SaveKey.Output>> {
    return query<T.SaveKey.Input, T.SaveKey.Output>(input, ClientAuth.admin, `SaveKey`);
  },

  saveKeychain(input: T.SaveKeychain.Input): Promise<T.Result<T.SaveKeychain.Output>> {
    return query<T.SaveKeychain.Input, T.SaveKeychain.Output>(
      input,
      ClientAuth.admin,
      `SaveKeychain`,
    );
  },

  saveNotification(
    input: T.SaveNotification_v0.Input,
  ): Promise<T.Result<T.SaveNotification_v0.Output>> {
    return query<T.SaveNotification_v0.Input, T.SaveNotification_v0.Output>(
      input,
      ClientAuth.admin,
      `SaveNotification_v0`,
    );
  },

  saveUser(input: T.SaveUser.Input): Promise<T.Result<T.SaveUser.Output>> {
    return query<T.SaveUser.Input, T.SaveUser.Output>(
      input,
      ClientAuth.admin,
      `SaveUser`,
    );
  },

  signup(input: T.Signup.Input): Promise<T.Result<T.Signup.Output>> {
    return query<T.Signup.Input, T.Signup.Output>(input, ClientAuth.none, `Signup`);
  },

  updateSuspendFilterRequest(
    input: T.UpdateSuspendFilterRequest.Input,
  ): Promise<T.Result<T.UpdateSuspendFilterRequest.Output>> {
    return query<T.UpdateSuspendFilterRequest.Input, T.UpdateSuspendFilterRequest.Output>(
      input,
      ClientAuth.admin,
      `UpdateSuspendFilterRequest`,
    );
  },

  updateUnlockRequest(
    input: T.UpdateUnlockRequest.Input,
  ): Promise<T.Result<T.UpdateUnlockRequest.Output>> {
    return query<T.UpdateUnlockRequest.Input, T.UpdateUnlockRequest.Output>(
      input,
      ClientAuth.admin,
      `UpdateUnlockRequest`,
    );
  },

  verifySignupEmail(
    input: T.VerifySignupEmail.Input,
  ): Promise<T.Result<T.VerifySignupEmail.Output>> {
    return query<T.VerifySignupEmail.Input, T.VerifySignupEmail.Output>(
      input,
      ClientAuth.none,
      `VerifySignupEmail`,
    );
  },
};

export type ApiClient = typeof liveClient;

export const throwingClient: ApiClient = {
  allowingSignups: () => {
    throw new Error(`ApiClient.allowingSignups() not implemented`);
  },
  confirmPendingNotificationMethod: () => {
    throw new Error(`ApiClient.confirmPendingNotificationMethod() not implemented`);
  },
  createBillingPortalSession: () => {
    throw new Error(`ApiClient.createBillingPortalSession() not implemented`);
  },
  createPendingAppConnection: () => {
    throw new Error(`ApiClient.createPendingAppConnection() not implemented`);
  },
  createPendingNotificationMethod: () => {
    throw new Error(`ApiClient.createPendingNotificationMethod() not implemented`);
  },
  deleteActivityItems: () => {
    throw new Error(`ApiClient.deleteActivityItems() not implemented`);
  },
  deleteEntity: () => {
    throw new Error(`ApiClient.deleteEntity() not implemented`);
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
  getCheckoutUrl: () => {
    throw new Error(`ApiClient.getCheckoutUrl() not implemented`);
  },
  getDashboardWidgets: () => {
    throw new Error(`ApiClient.getDashboardWidgets() not implemented`);
  },
  getIdentifiedApps: () => {
    throw new Error(`ApiClient.getIdentifiedApps() not implemented`);
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
  getUserActivityDay: () => {
    throw new Error(`ApiClient.getUserActivityDay() not implemented`);
  },
  getUserActivityDays: () => {
    throw new Error(`ApiClient.getUserActivityDays() not implemented`);
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
  joinWaitlist: () => {
    throw new Error(`ApiClient.joinWaitlist() not implemented`);
  },
  loginMagicLink: () => {
    throw new Error(`ApiClient.loginMagicLink() not implemented`);
  },
  requestMagicLink: () => {
    throw new Error(`ApiClient.requestMagicLink() not implemented`);
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
  signup: () => {
    throw new Error(`ApiClient.signup() not implemented`);
  },
  updateSuspendFilterRequest: () => {
    throw new Error(`ApiClient.updateSuspendFilterRequest() not implemented`);
  },
  updateUnlockRequest: () => {
    throw new Error(`ApiClient.updateUnlockRequest() not implemented`);
  },
  verifySignupEmail: () => {
    throw new Error(`ApiClient.verifySignupEmail() not implemented`);
  },
};
