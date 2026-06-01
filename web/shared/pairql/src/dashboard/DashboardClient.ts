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

  public approveMusicAlbum = (
    input: P.ApproveMusicAlbum.Input,
  ): Promise<Result<P.ApproveMusicAlbum.Output>> => {
    return this.query<P.ApproveMusicAlbum.Output>(input, `ApproveMusicAlbum`, `parent`);
  };

  public changeSubscriptionTier = (
    input: P.ChangeSubscriptionTier.Input,
  ): Promise<Result<P.ChangeSubscriptionTier.Output>> => {
    return this.query<P.ChangeSubscriptionTier.Output>(
      input,
      `ChangeSubscriptionTier`,
      `parent`,
    );
  };

  public childActivitySummaries = (
    input: P.ChildActivitySummaries.Input,
  ): Promise<Result<P.ChildActivitySummaries.Output>> => {
    return this.query<P.ChildActivitySummaries.Output>(
      input,
      `ChildActivitySummaries`,
      `parent`,
    );
  };

  public claimAmDevice = (
    input: P.ClaimAmDevice.Input,
  ): Promise<Result<P.ClaimAmDevice.Output>> => {
    return this.query<P.ClaimAmDevice.Output>(input, `ClaimAmDevice`, `parent`);
  };

  public claimIOSDevice = (
    input: P.ClaimIOSDevice.Input,
  ): Promise<Result<P.ClaimIOSDevice.Output>> => {
    return this.query<P.ClaimIOSDevice.Output>(input, `ClaimIOSDevice`, `parent`);
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
    input: P.DashboardWidgets_v2.Input,
  ): Promise<Result<P.DashboardWidgets_v2.Output>> => {
    return this.query<P.DashboardWidgets_v2.Output>(
      input,
      `DashboardWidgets_v2`,
      `parent`,
    );
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

  public getAccountOwner = (
    input: P.GetAccountOwner_v2.Input,
  ): Promise<Result<P.GetAccountOwner_v2.Output>> => {
    return this.query<P.GetAccountOwner_v2.Output>(input, `GetAccountOwner_v2`, `parent`);
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

  public getAllDevices = (
    input: P.GetAllDevices.Input,
  ): Promise<Result<P.GetAllDevices.Output>> => {
    return this.query<P.GetAllDevices.Output>(input, `GetAllDevices`, `parent`);
  };

  public getAmClaimData = (
    input: P.GetAmClaimData.Input,
  ): Promise<Result<P.GetAmClaimData.Output>> => {
    return this.query<P.GetAmClaimData.Output>(input, `GetAmClaimData`, `parent`);
  };

  public getApprovedMusicAlbums = (
    input: P.GetApprovedMusicAlbums.Input,
  ): Promise<Result<P.GetApprovedMusicAlbums.Output>> => {
    return this.query<P.GetApprovedMusicAlbums.Output>(
      input,
      `GetApprovedMusicAlbums`,
      `parent`,
    );
  };

  public getBatchUnlockRequestData = (
    input: P.GetBatchUnlockRequestData.Input,
  ): Promise<Result<P.GetBatchUnlockRequestData.Output>> => {
    return this.query<P.GetBatchUnlockRequestData.Output>(
      input,
      `GetBatchUnlockRequestData`,
      `parent`,
    );
  };

  public getChild = (input: P.GetChild.Input): Promise<Result<P.GetChild.Output>> => {
    return this.query<P.GetChild.Output>(input, `GetChild`, `parent`);
  };

  public getChildren = (
    input: P.GetChildren.Input,
  ): Promise<Result<P.GetChildren.Output>> => {
    return this.query<P.GetChildren.Output>(input, `GetChildren`, `parent`);
  };

  public getDevice = (input: P.GetDevice.Input): Promise<Result<P.GetDevice.Output>> => {
    return this.query<P.GetDevice.Output>(input, `GetDevice`, `parent`);
  };

  public getIOSDevice = (
    input: P.GetIOSDevice_v2.Input,
  ): Promise<Result<P.GetIOSDevice_v2.Output>> => {
    return this.query<P.GetIOSDevice_v2.Output>(input, `GetIOSDevice_v2`, `parent`);
  };

  public getIOSDeviceClaimData = (
    input: P.GetIOSDeviceClaimData.Input,
  ): Promise<Result<P.GetIOSDeviceClaimData.Output>> => {
    return this.query<P.GetIOSDeviceClaimData.Output>(
      input,
      `GetIOSDeviceClaimData`,
      `parent`,
    );
  };

  public getIOSDeviceSupervisionStatus = (
    input: P.GetIOSDeviceSupervisionStatus.Input,
  ): Promise<Result<P.GetIOSDeviceSupervisionStatus.Output>> => {
    return this.query<P.GetIOSDeviceSupervisionStatus.Output>(
      input,
      `GetIOSDeviceSupervisionStatus`,
      `parent`,
    );
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

  public getSubscriptionPanel = (
    input: P.GetSubscriptionPanel_v2.Input,
  ): Promise<Result<P.GetSubscriptionPanel_v2.Output>> => {
    return this.query<P.GetSubscriptionPanel_v2.Output>(
      input,
      `GetSubscriptionPanel_v2`,
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

  public handleUnlockRequests = (
    input: P.HandleUnlockRequests.Input,
  ): Promise<Result<P.HandleUnlockRequests.Output>> => {
    return this.query<P.HandleUnlockRequests.Output>(
      input,
      `HandleUnlockRequests`,
      `parent`,
    );
  };

  public iOSAppConnectionCode = (
    input: P.IOSAppConnectionCode.Input,
  ): Promise<Result<P.IOSAppConnectionCode.Output>> => {
    return this.query<P.IOSAppConnectionCode.Output>(
      input,
      `IOSAppConnectionCode`,
      `parent`,
    );
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

  public macAppConnectionCode = (
    input: P.MacAppConnectionCode.Input,
  ): Promise<Result<P.MacAppConnectionCode.Output>> => {
    return this.query<P.MacAppConnectionCode.Output>(
      input,
      `MacAppConnectionCode`,
      `parent`,
    );
  };

  public openBillingPortal = (
    input: P.OpenBillingPortal.Input,
  ): Promise<Result<P.OpenBillingPortal.Output>> => {
    return this.query<P.OpenBillingPortal.Output>(input, `OpenBillingPortal`, `parent`);
  };

  public prepIOSAppConnection = (
    input: P.PrepIOSAppConnection.Input,
  ): Promise<Result<P.PrepIOSAppConnection.Output>> => {
    return this.query<P.PrepIOSAppConnection.Output>(
      input,
      `PrepIOSAppConnection`,
      `parent`,
    );
  };

  public removeApprovedMusicAlbum = (
    input: P.RemoveApprovedMusicAlbum.Input,
  ): Promise<Result<P.RemoveApprovedMusicAlbum.Output>> => {
    return this.query<P.RemoveApprovedMusicAlbum.Output>(
      input,
      `RemoveApprovedMusicAlbum`,
      `parent`,
    );
  };

  public requestAmPinReset = (
    input: P.RequestAmPinReset.Input,
  ): Promise<Result<P.RequestAmPinReset.Output>> => {
    return this.query<P.RequestAmPinReset.Output>(input, `RequestAmPinReset`, `parent`);
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

  public searchMusicCatalog = (
    input: P.SearchMusicCatalog.Input,
  ): Promise<Result<P.SearchMusicCatalog.Output>> => {
    return this.query<P.SearchMusicCatalog.Output>(input, `SearchMusicCatalog`, `parent`);
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

  public startCheckoutSession = (
    input: P.StartCheckoutSession.Input,
  ): Promise<Result<P.StartCheckoutSession.Output>> => {
    return this.query<P.StartCheckoutSession.Output>(
      input,
      `StartCheckoutSession`,
      `parent`,
    );
  };

  public startFullTrial = (
    input: P.StartFullTrial.Input,
  ): Promise<Result<P.StartFullTrial.Output>> => {
    return this.query<P.StartFullTrial.Output>(input, `StartFullTrial`, `parent`);
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
