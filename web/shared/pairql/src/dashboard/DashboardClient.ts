// auto-generated, do not edit
import type * as P from '.';
import type Result from '../Result';
import type { PrepareRequest } from '../types';
import type { ClientAuth as Auth } from './shared';
import Client from '../Client';

export default class DashboardClient extends Client<Auth> {
  public constructor(endpoint: string, prepareRequest: PrepareRequest<Auth>) {
    super(endpoint, `dashboard`, prepareRequest);
  }

  public childActivitySummaries = (
    input: P.ChildActivitySummaries.Input,
  ): Promise<Result<P.ChildActivitySummaries.Output>> => {
    return this.query<P.ChildActivitySummaries.Output>(
      input,
      `ChildActivitySummaries`,
      `parent`,
    );
  };

  public combinedUsersActivityFeed = (
    input: P.CombinedUsersActivityFeed.Input,
  ): Promise<Result<P.CombinedUsersActivityFeed.Output>> => {
    return this.query<P.CombinedUsersActivityFeed.Output>(
      input,
      `CombinedUsersActivityFeed`,
      `parent`,
    );
  };

  public confirmPendingNotificationMethod = (
    input: P.ConfirmPendingNotificationMethod.Input,
  ): Promise<Result<P.ConfirmPendingNotificationMethod.Output>> => {
    return this.query<P.ConfirmPendingNotificationMethod.Output>(
      input,
      `ConfirmPendingNotificationMethod`,
      `parent`,
    );
  };

  public createPendingAppConnection = (
    input: P.CreatePendingAppConnection.Input,
  ): Promise<Result<P.CreatePendingAppConnection.Output>> => {
    return this.query<P.CreatePendingAppConnection.Output>(
      input,
      `CreatePendingAppConnection`,
      `parent`,
    );
  };

  public createPendingNotificationMethod = (
    input: P.CreatePendingNotificationMethod.Input,
  ): Promise<Result<P.CreatePendingNotificationMethod.Output>> => {
    return this.query<P.CreatePendingNotificationMethod.Output>(
      input,
      `CreatePendingNotificationMethod`,
      `parent`,
    );
  };

  public dashboardWidgets = (
    input: P.DashboardWidgets.Input,
  ): Promise<Result<P.DashboardWidgets.Output>> => {
    return this.query<P.DashboardWidgets.Output>(input, `DashboardWidgets`, `parent`);
  };

  public decideFilterSuspensionRequest = (
    input: P.DecideFilterSuspensionRequest.Input,
  ): Promise<Result<P.DecideFilterSuspensionRequest.Output>> => {
    return this.query<P.DecideFilterSuspensionRequest.Output>(
      input,
      `DecideFilterSuspensionRequest`,
      `parent`,
    );
  };

  public deleteActivityItems = (
    input: P.DeleteActivityItems_v2.Input,
  ): Promise<Result<P.DeleteActivityItems_v2.Output>> => {
    return this.query<P.DeleteActivityItems_v2.Output>(
      input,
      `DeleteActivityItems_v2`,
      `parent`,
    );
  };

  public deleteEntity = (
    input: P.DeleteEntity_v2.Input,
  ): Promise<Result<P.DeleteEntity_v2.Output>> => {
    return this.query<P.DeleteEntity_v2.Output>(input, `DeleteEntity_v2`, `parent`);
  };

  public familyActivitySummaries = (
    input: P.FamilyActivitySummaries.Input,
  ): Promise<Result<P.FamilyActivitySummaries.Output>> => {
    return this.query<P.FamilyActivitySummaries.Output>(
      input,
      `FamilyActivitySummaries`,
      `parent`,
    );
  };

  public flagActivityItems = (
    input: P.FlagActivityItems.Input,
  ): Promise<Result<P.FlagActivityItems.Output>> => {
    return this.query<P.FlagActivityItems.Output>(input, `FlagActivityItems`, `parent`);
  };

  public getAdmin = (input: P.GetAdmin.Input): Promise<Result<P.GetAdmin.Output>> => {
    return this.query<P.GetAdmin.Output>(input, `GetAdmin`, `parent`);
  };

  public getAdminKeychain = (
    input: P.GetAdminKeychain.Input,
  ): Promise<Result<P.GetAdminKeychain.Output>> => {
    return this.query<P.GetAdminKeychain.Output>(input, `GetAdminKeychain`, `parent`);
  };

  public getAdminKeychains = (
    input: P.GetAdminKeychains.Input,
  ): Promise<Result<P.GetAdminKeychains.Output>> => {
    return this.query<P.GetAdminKeychains.Output>(input, `GetAdminKeychains`, `parent`);
  };

  public getDevice = (input: P.GetDevice.Input): Promise<Result<P.GetDevice.Output>> => {
    return this.query<P.GetDevice.Output>(input, `GetDevice`, `parent`);
  };

  public getDevices = (
    input: P.GetDevices.Input,
  ): Promise<Result<P.GetDevices.Output>> => {
    return this.query<P.GetDevices.Output>(input, `GetDevices`, `parent`);
  };

  public getIOSDevice = (
    input: P.GetIOSDevice.Input,
  ): Promise<Result<P.GetIOSDevice.Output>> => {
    return this.query<P.GetIOSDevice.Output>(input, `GetIOSDevice`, `parent`);
  };

  public getIdentifiedApps = (
    input: P.GetIdentifiedApps.Input,
  ): Promise<Result<P.GetIdentifiedApps.Output>> => {
    return this.query<P.GetIdentifiedApps.Output>(input, `GetIdentifiedApps`, `parent`);
  };

  public getSelectableKeychains = (
    input: P.GetSelectableKeychains.Input,
  ): Promise<Result<P.GetSelectableKeychains.Output>> => {
    return this.query<P.GetSelectableKeychains.Output>(
      input,
      `GetSelectableKeychains`,
      `parent`,
    );
  };

  public getSuspendFilterRequest = (
    input: P.GetSuspendFilterRequest.Input,
  ): Promise<Result<P.GetSuspendFilterRequest.Output>> => {
    return this.query<P.GetSuspendFilterRequest.Output>(
      input,
      `GetSuspendFilterRequest`,
      `parent`,
    );
  };

  public getUnlockRequest = (
    input: P.GetUnlockRequest.Input,
  ): Promise<Result<P.GetUnlockRequest.Output>> => {
    return this.query<P.GetUnlockRequest.Output>(input, `GetUnlockRequest`, `parent`);
  };

  public getUnlockRequests = (
    input: P.GetUnlockRequests.Input,
  ): Promise<Result<P.GetUnlockRequests.Output>> => {
    return this.query<P.GetUnlockRequests.Output>(input, `GetUnlockRequests`, `parent`);
  };

  public getUser = (input: P.GetUser.Input): Promise<Result<P.GetUser.Output>> => {
    return this.query<P.GetUser.Output>(input, `GetUser`, `parent`);
  };

  public getUserUnlockRequests = (
    input: P.GetUserUnlockRequests.Input,
  ): Promise<Result<P.GetUserUnlockRequests.Output>> => {
    return this.query<P.GetUserUnlockRequests.Output>(
      input,
      `GetUserUnlockRequests`,
      `parent`,
    );
  };

  public getUsers = (input: P.GetUsers.Input): Promise<Result<P.GetUsers.Output>> => {
    return this.query<P.GetUsers.Output>(input, `GetUsers`, `parent`);
  };

  public handleCheckoutCancel = (
    input: P.HandleCheckoutCancel.Input,
  ): Promise<Result<P.HandleCheckoutCancel.Output>> => {
    return this.query<P.HandleCheckoutCancel.Output>(
      input,
      `HandleCheckoutCancel`,
      `parent`,
    );
  };

  public handleCheckoutSuccess = (
    input: P.HandleCheckoutSuccess.Input,
  ): Promise<Result<P.HandleCheckoutSuccess.Output>> => {
    return this.query<P.HandleCheckoutSuccess.Output>(
      input,
      `HandleCheckoutSuccess`,
      `parent`,
    );
  };

  public iOSDevices = (
    input: P.IOSDevices.Input,
  ): Promise<Result<P.IOSDevices.Output>> => {
    return this.query<P.IOSDevices.Output>(input, `IOSDevices`, `parent`);
  };

  public latestAppVersions = (
    input: P.LatestAppVersions.Input,
  ): Promise<Result<P.LatestAppVersions.Output>> => {
    return this.query<P.LatestAppVersions.Output>(input, `LatestAppVersions`, `parent`);
  };

  public logEvent = (input: P.LogEvent.Input): Promise<Result<P.LogEvent.Output>> => {
    return this.query<P.LogEvent.Output>(input, `LogEvent`, `parent`);
  };

  public login = (input: P.Login.Input): Promise<Result<P.Login.Output>> => {
    return this.query<P.Login.Output>(input, `Login`, `none`);
  };

  public loginMagicLink = (
    input: P.LoginMagicLink.Input,
  ): Promise<Result<P.LoginMagicLink.Output>> => {
    return this.query<P.LoginMagicLink.Output>(input, `LoginMagicLink`, `none`);
  };

  public requestMagicLink = (
    input: P.RequestMagicLink.Input,
  ): Promise<Result<P.RequestMagicLink.Output>> => {
    return this.query<P.RequestMagicLink.Output>(input, `RequestMagicLink`, `none`);
  };

  public requestPublicKeychain = (
    input: P.RequestPublicKeychain.Input,
  ): Promise<Result<P.RequestPublicKeychain.Output>> => {
    return this.query<P.RequestPublicKeychain.Output>(
      input,
      `RequestPublicKeychain`,
      `parent`,
    );
  };

  public resetPassword = (
    input: P.ResetPassword.Input,
  ): Promise<Result<P.ResetPassword.Output>> => {
    return this.query<P.ResetPassword.Output>(input, `ResetPassword`, `none`);
  };

  public saveConferenceEmail = (
    input: P.SaveConferenceEmail.Input,
  ): Promise<Result<P.SaveConferenceEmail.Output>> => {
    return this.query<P.SaveConferenceEmail.Output>(input, `SaveConferenceEmail`, `none`);
  };

  public saveDevice = (
    input: P.SaveDevice.Input,
  ): Promise<Result<P.SaveDevice.Output>> => {
    return this.query<P.SaveDevice.Output>(input, `SaveDevice`, `parent`);
  };

  public saveKey = (input: P.SaveKey.Input): Promise<Result<P.SaveKey.Output>> => {
    return this.query<P.SaveKey.Output>(input, `SaveKey`, `parent`);
  };

  public saveKeychain = (
    input: P.SaveKeychain.Input,
  ): Promise<Result<P.SaveKeychain.Output>> => {
    return this.query<P.SaveKeychain.Output>(input, `SaveKeychain`, `parent`);
  };

  public saveNotification = (
    input: P.SaveNotification.Input,
  ): Promise<Result<P.SaveNotification.Output>> => {
    return this.query<P.SaveNotification.Output>(input, `SaveNotification`, `parent`);
  };

  public saveUser = (input: P.SaveUser.Input): Promise<Result<P.SaveUser.Output>> => {
    return this.query<P.SaveUser.Output>(input, `SaveUser`, `parent`);
  };

  public securityEventsFeed = (
    input: P.SecurityEventsFeed.Input,
  ): Promise<Result<P.SecurityEventsFeed.Output>> => {
    return this.query<P.SecurityEventsFeed.Output>(input, `SecurityEventsFeed`, `parent`);
  };

  public sendPasswordResetEmail = (
    input: P.SendPasswordResetEmail.Input,
  ): Promise<Result<P.SendPasswordResetEmail.Output>> => {
    return this.query<P.SendPasswordResetEmail.Output>(
      input,
      `SendPasswordResetEmail`,
      `none`,
    );
  };

  public signup = (input: P.Signup.Input): Promise<Result<P.Signup.Output>> => {
    return this.query<P.Signup.Output>(input, `Signup`, `none`);
  };

  public stripeUrl = (input: P.StripeUrl.Input): Promise<Result<P.StripeUrl.Output>> => {
    return this.query<P.StripeUrl.Output>(input, `StripeUrl`, `parent`);
  };

  public toggleChildKeychain = (
    input: P.ToggleChildKeychain.Input,
  ): Promise<Result<P.ToggleChildKeychain.Output>> => {
    return this.query<P.ToggleChildKeychain.Output>(
      input,
      `ToggleChildKeychain`,
      `parent`,
    );
  };

  public updateIOSDevice = (
    input: P.UpdateIOSDevice.Input,
  ): Promise<Result<P.UpdateIOSDevice.Output>> => {
    return this.query<P.UpdateIOSDevice.Output>(input, `UpdateIOSDevice`, `parent`);
  };

  public updateUnlockRequest = (
    input: P.UpdateUnlockRequest.Input,
  ): Promise<Result<P.UpdateUnlockRequest.Output>> => {
    return this.query<P.UpdateUnlockRequest.Output>(
      input,
      `UpdateUnlockRequest`,
      `parent`,
    );
  };

  public upsertBlockRule = (
    input: P.UpsertBlockRule.Input,
  ): Promise<Result<P.UpsertBlockRule.Output>> => {
    return this.query<P.UpsertBlockRule.Output>(input, `UpsertBlockRule`, `parent`);
  };

  public userActivityFeed = (
    input: P.UserActivityFeed.Input,
  ): Promise<Result<P.UserActivityFeed.Output>> => {
    return this.query<P.UserActivityFeed.Output>(input, `UserActivityFeed`, `parent`);
  };

  public verifySignupEmail = (
    input: P.VerifySignupEmail.Input,
  ): Promise<Result<P.VerifySignupEmail.Output>> => {
    return this.query<P.VerifySignupEmail.Output>(input, `VerifySignupEmail`, `none`);
  };
}

export type { P };
