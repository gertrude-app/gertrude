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
  slug: `GetAccountOwner`,
  output: T.GetAccountOwner.Output,
): void;
export function interceptPql(
  slug: `GetAdminKeychain`,
  output: T.GetAdminKeychain.Output,
): void;
export function interceptPql(
  slug: `GetAdminKeychains`,
  output: T.GetAdminKeychains.Output,
): void;
export function interceptPql(slug: `GetChild`, output: T.GetChild.Output): void;
export function interceptPql(slug: `GetChildren`, output: T.GetChildren.Output): void;
export function interceptPql(slug: `GetDevice`, output: T.GetDevice.Output): void;
export function interceptPql(slug: `GetDevices`, output: T.GetDevices.Output): void;
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
  slug: `GetSuspendFilterRequest`,
  output: T.GetSuspendFilterRequest.Output,
): void;
export function interceptPql(
  slug: `GetUnlockRequest`,
  output: T.GetUnlockRequest.Output,
): void;
export function interceptPql(
  slug: `GetUnlockRequests`,
  output: T.GetUnlockRequests.Output,
): void;
export function interceptPql(
  slug: `GetUserUnlockRequests`,
  output: T.GetUserUnlockRequests.Output,
): void;
export function interceptPql(
  slug: `HandleCheckoutCancel`,
  output: T.HandleCheckoutCancel.Output,
): void;
export function interceptPql(
  slug: `HandleCheckoutSuccess`,
  output: T.HandleCheckoutSuccess.Output,
): void;
export function interceptPql(slug: `IOSDevices`, output: T.IOSDevices.Output): void;
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
  slug: `StartFullTrial`,
  output: T.StartFullTrial.Output,
): void;
export function interceptPql(slug: `StripeUrl_v2`, output: T.StripeUrl_v2.Output): void;
export function interceptPql(
  slug: `ToggleChildKeychain`,
  output: T.ToggleChildKeychain.Output,
): void;
export function interceptPql(
  slug: `UpdateIOSDevice`,
  output: T.UpdateIOSDevice.Output,
): void;
export function interceptPql(
  slug: `UpdateUnlockRequest`,
  output: T.UpdateUnlockRequest.Output,
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
    | `GetAccountOwner`
    | `GetAdminKeychain`
    | `GetAdminKeychains`
    | `GetChild`
    | `GetChildren`
    | `GetDevice`
    | `GetDevices`
    | `GetIOSDevice`
    | `GetIOSDeviceClaimData`
    | `GetIOSDeviceSupervisionStatus`
    | `GetIdentifiedApps`
    | `GetSelectableKeychains`
    | `GetSuspendFilterRequest`
    | `GetUnlockRequest`
    | `GetUnlockRequests`
    | `GetUserUnlockRequests`
    | `HandleCheckoutCancel`
    | `HandleCheckoutSuccess`
    | `IOSDevices`
    | `LatestAppVersions`
    | `LogEvent`
    | `Login`
    | `LoginMagicLink`
    | `MacAppConnectionCode`
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
    | `StartFullTrial`
    | `StripeUrl_v2`
    | `ToggleChildKeychain`
    | `UpdateIOSDevice`
    | `UpdateUnlockRequest`
    | `UpsertBlockRule`
    | `UserActivityFeed`
    | `VerifySignupEmail`,
  details: Record<string, any> = {},
): void {
  cy.intercept(`/pairql/dashboard/${slug}`, { __cyStubbedError: true, ...details });
}
