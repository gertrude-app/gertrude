// auto-generated, do not edit
import type * as T from '@dash/types';

export function interceptPql(
  slug: `ChildActivitySummaries`,
  output: T.ChildActivitySummaries.Output,
): void;
export function interceptPql(
  slug: `ClaimIOSDevice`,
  output: T.ClaimIOSDevice.Output,
): void;
export function interceptPql(
  slug: `CombinedUsersActivityFeed`,
  output: T.CombinedUsersActivityFeed.Output,
): void;
export function interceptPql(
  slug: `ConfirmPendingNotificationMethod`,
  output: T.ConfirmPendingNotificationMethod.Output,
): void;
export function interceptPql(
  slug: `CreatePendingNotificationMethod`,
  output: T.CreatePendingNotificationMethod.Output,
): void;
export function interceptPql(
  slug: `DashboardWidgets_v2`,
  output: T.DashboardWidgets_v2.Output,
): void;
export function interceptPql(
  slug: `DecideFilterSuspensionRequest`,
  output: T.DecideFilterSuspensionRequest.Output,
): void;
export function interceptPql(
  slug: `DeleteActivityItems_v2`,
  output: T.DeleteActivityItems_v2.Output,
): void;
export function interceptPql(
  slug: `DeleteEntity_v2`,
  output: T.DeleteEntity_v2.Output,
): void;
export function interceptPql(
  slug: `FamilyActivitySummaries`,
  output: T.FamilyActivitySummaries.Output,
): void;
export function interceptPql(
  slug: `FlagActivityItems`,
  output: T.FlagActivityItems.Output,
): void;
export function interceptPql(
  slug: `GetAccountOwner_v2`,
  output: T.GetAccountOwner_v2.Output,
): void;
export function interceptPql(
  slug: `GetAdminKeychain`,
  output: T.GetAdminKeychain.Output,
): void;
export function interceptPql(
  slug: `GetAdminKeychains`,
  output: T.GetAdminKeychains.Output,
): void;
export function interceptPql(slug: `GetAllDevices`, output: T.GetAllDevices.Output): void;
export function interceptPql(
  slug: `GetBatchUnlockRequestData`,
  output: T.GetBatchUnlockRequestData.Output,
): void;
export function interceptPql(slug: `GetChild`, output: T.GetChild.Output): void;
export function interceptPql(slug: `GetChildren`, output: T.GetChildren.Output): void;
export function interceptPql(slug: `GetDevice`, output: T.GetDevice.Output): void;
export function interceptPql(slug: `GetIOSDevice`, output: T.GetIOSDevice.Output): void;
export function interceptPql(
  slug: `GetIOSDeviceClaimData`,
  output: T.GetIOSDeviceClaimData.Output,
): void;
export function interceptPql(
  slug: `GetIOSDeviceSupervisionStatus`,
  output: T.GetIOSDeviceSupervisionStatus.Output,
): void;
export function interceptPql(
  slug: `GetIdentifiedApps`,
  output: T.GetIdentifiedApps.Output,
): void;
export function interceptPql(
  slug: `GetSelectableKeychains`,
  output: T.GetSelectableKeychains.Output,
): void;
export function interceptPql(
  slug: `GetSubscriptionPanel_v2`,
  output: T.GetSubscriptionPanel_v2.Output,
): void;
export function interceptPql(
  slug: `GetSuspendFilterRequest`,
  output: T.GetSuspendFilterRequest.Output,
): void;
export function interceptPql(
  slug: `HandleCheckoutCancel`,
  output: T.HandleCheckoutCancel.Output,
): void;
export function interceptPql(
  slug: `HandleCheckoutSuccess`,
  output: T.HandleCheckoutSuccess.Output,
): void;
export function interceptPql(
  slug: `HandleUnlockRequests`,
  output: T.HandleUnlockRequests.Output,
): void;
export function interceptPql(
  slug: `IOSAppConnectionCode`,
  output: T.IOSAppConnectionCode.Output,
): void;
export function interceptPql(
  slug: `LatestAppVersions`,
  output: T.LatestAppVersions.Output,
): void;
export function interceptPql(slug: `LogEvent`, output: T.LogEvent.Output): void;
export function interceptPql(slug: `Login`, output: T.Login.Output): void;
export function interceptPql(
  slug: `LoginMagicLink`,
  output: T.LoginMagicLink.Output,
): void;
export function interceptPql(
  slug: `MacAppConnectionCode`,
  output: T.MacAppConnectionCode.Output,
): void;
export function interceptPql(
  slug: `OpenBillingPortal`,
  output: T.OpenBillingPortal.Output,
): void;
export function interceptPql(
  slug: `PrepIOSAppConnection`,
  output: T.PrepIOSAppConnection.Output,
): void;
export function interceptPql(
  slug: `RequestMagicLink`,
  output: T.RequestMagicLink.Output,
): void;
export function interceptPql(
  slug: `RequestPublicKeychain`,
  output: T.RequestPublicKeychain.Output,
): void;
export function interceptPql(slug: `ResetPassword`, output: T.ResetPassword.Output): void;
export function interceptPql(
  slug: `SaveConferenceEmail`,
  output: T.SaveConferenceEmail.Output,
): void;
export function interceptPql(slug: `SaveDevice`, output: T.SaveDevice.Output): void;
export function interceptPql(slug: `SaveKey`, output: T.SaveKey.Output): void;
export function interceptPql(slug: `SaveKeychain`, output: T.SaveKeychain.Output): void;
export function interceptPql(
  slug: `SaveNotification`,
  output: T.SaveNotification.Output,
): void;
export function interceptPql(slug: `SaveUser`, output: T.SaveUser.Output): void;
export function interceptPql(
  slug: `SecurityEventsFeed`,
  output: T.SecurityEventsFeed.Output,
): void;
export function interceptPql(
  slug: `SendPasswordResetEmail`,
  output: T.SendPasswordResetEmail.Output,
): void;
export function interceptPql(slug: `Signup`, output: T.Signup.Output): void;
export function interceptPql(
  slug: `StartCheckoutSession`,
  output: T.StartCheckoutSession.Output,
): void;
export function interceptPql(
  slug: `StartFullTrial`,
  output: T.StartFullTrial.Output,
): void;
export function interceptPql(
  slug: `ToggleChildKeychain`,
  output: T.ToggleChildKeychain.Output,
): void;
export function interceptPql(
  slug: `UpdateIOSDevice`,
  output: T.UpdateIOSDevice.Output,
): void;
export function interceptPql(
  slug: `UpgradeSubscriptionTier`,
  output: T.UpgradeSubscriptionTier.Output,
): void;
export function interceptPql(
  slug: `UpsertBlockRule`,
  output: T.UpsertBlockRule.Output,
): void;
export function interceptPql(
  slug: `UserActivityFeed`,
  output: T.UserActivityFeed.Output,
): void;
export function interceptPql(
  slug: `VerifySignupEmail`,
  output: T.VerifySignupEmail.Output,
): void;

export function interceptPql(slug: string, output: any): void {
  // cypress chokes on the empty object, doesn't understand it should reply w/ it
  const res = JSON.stringify(output) === `{}` ? `{}` : output;
  cy.intercept(`/pairql/dashboard/${slug}`, (req) => req.reply(res)).as(slug);
}

export function forcePqlErr(
  slug:
    | `ChildActivitySummaries`
    | `ClaimIOSDevice`
    | `CombinedUsersActivityFeed`
    | `ConfirmPendingNotificationMethod`
    | `CreatePendingNotificationMethod`
    | `DashboardWidgets_v2`
    | `DecideFilterSuspensionRequest`
    | `DeleteActivityItems_v2`
    | `DeleteEntity_v2`
    | `FamilyActivitySummaries`
    | `FlagActivityItems`
    | `GetAccountOwner_v2`
    | `GetAdminKeychain`
    | `GetAdminKeychains`
    | `GetAllDevices`
    | `GetBatchUnlockRequestData`
    | `GetChild`
    | `GetChildren`
    | `GetDevice`
    | `GetIOSDevice`
    | `GetIOSDeviceClaimData`
    | `GetIOSDeviceSupervisionStatus`
    | `GetIdentifiedApps`
    | `GetSelectableKeychains`
    | `GetSubscriptionPanel_v2`
    | `GetSuspendFilterRequest`
    | `HandleCheckoutCancel`
    | `HandleCheckoutSuccess`
    | `HandleUnlockRequests`
    | `IOSAppConnectionCode`
    | `LatestAppVersions`
    | `LogEvent`
    | `Login`
    | `LoginMagicLink`
    | `MacAppConnectionCode`
    | `OpenBillingPortal`
    | `PrepIOSAppConnection`
    | `RequestMagicLink`
    | `RequestPublicKeychain`
    | `ResetPassword`
    | `SaveConferenceEmail`
    | `SaveDevice`
    | `SaveKey`
    | `SaveKeychain`
    | `SaveNotification`
    | `SaveUser`
    | `SecurityEventsFeed`
    | `SendPasswordResetEmail`
    | `Signup`
    | `StartCheckoutSession`
    | `StartFullTrial`
    | `ToggleChildKeychain`
    | `UpdateIOSDevice`
    | `UpgradeSubscriptionTier`
    | `UpsertBlockRule`
    | `UserActivityFeed`
    | `VerifySignupEmail`,
  details: Record<string, any> = {},
): void {
  cy.intercept(`/pairql/dashboard/${slug}`, { __cyStubbedError: true, ...details });
}
