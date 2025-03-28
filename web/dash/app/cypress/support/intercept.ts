// auto-generated, do not edit
import type * as T from '@dash/types';

export function interceptPql(
  slug: `CombinedUsersActivityFeed`,
  output: T.CombinedUsersActivityFeed.Output,
): void;
export function interceptPql(
  slug: `CombinedUsersActivitySummaries`,
  output: T.CombinedUsersActivitySummaries.Output,
): void;
export function interceptPql(
  slug: `ConfirmPendingNotificationMethod`,
  output: T.ConfirmPendingNotificationMethod.Output,
): void;
export function interceptPql(
  slug: `CreatePendingAppConnection`,
  output: T.CreatePendingAppConnection.Output,
): void;
export function interceptPql(
  slug: `CreatePendingNotificationMethod`,
  output: T.CreatePendingNotificationMethod.Output,
): void;
export function interceptPql(
  slug: `DecideFilterSuspensionRequest`,
  output: T.DecideFilterSuspensionRequest.Output,
): void;
export function interceptPql(
  slug: `DeleteActivityItems_v2`,
  output: T.DeleteActivityItems_v2.Output,
): void;
export function interceptPql(slug: `DeleteEntity`, output: T.DeleteEntity.Output): void;
export function interceptPql(slug: `GetAdmin`, output: T.GetAdmin.Output): void;
export function interceptPql(
  slug: `GetAdminKeychain`,
  output: T.GetAdminKeychain.Output,
): void;
export function interceptPql(
  slug: `GetAdminKeychains`,
  output: T.GetAdminKeychains.Output,
): void;
export function interceptPql(
  slug: `GetDashboardWidgets`,
  output: T.GetDashboardWidgets.Output,
): void;
export function interceptPql(slug: `GetDevice`, output: T.GetDevice.Output): void;
export function interceptPql(slug: `GetDevices`, output: T.GetDevices.Output): void;
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
export function interceptPql(slug: `GetUser`, output: T.GetUser.Output): void;
export function interceptPql(slug: `GetUsers`, output: T.GetUsers.Output): void;
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
export function interceptPql(slug: `StripeUrl`, output: T.StripeUrl.Output): void;
export function interceptPql(
  slug: `ToggleChildKeychain`,
  output: T.ToggleChildKeychain.Output,
): void;
export function interceptPql(
  slug: `UpdateUnlockRequest`,
  output: T.UpdateUnlockRequest.Output,
): void;
export function interceptPql(
  slug: `UserActivityFeed`,
  output: T.UserActivityFeed.Output,
): void;
export function interceptPql(
  slug: `UserActivitySummaries`,
  output: T.UserActivitySummaries.Output,
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
    | 'CombinedUsersActivityFeed'
    | 'CombinedUsersActivitySummaries'
    | 'ConfirmPendingNotificationMethod'
    | 'CreatePendingAppConnection'
    | 'CreatePendingNotificationMethod'
    | 'DecideFilterSuspensionRequest'
    | 'DeleteActivityItems_v2'
    | 'DeleteEntity'
    | 'GetAdmin'
    | 'GetAdminKeychain'
    | 'GetAdminKeychains'
    | 'GetDashboardWidgets'
    | 'GetDevice'
    | 'GetDevices'
    | 'GetIdentifiedApps'
    | 'GetSelectableKeychains'
    | 'GetSuspendFilterRequest'
    | 'GetUnlockRequest'
    | 'GetUnlockRequests'
    | 'GetUser'
    | 'GetUsers'
    | 'GetUserUnlockRequests'
    | 'HandleCheckoutCancel'
    | 'HandleCheckoutSuccess'
    | 'LatestAppVersions'
    | 'LogEvent'
    | 'Login'
    | 'LoginMagicLink'
    | 'RequestMagicLink'
    | 'RequestPublicKeychain'
    | 'ResetPassword'
    | 'SaveConferenceEmail'
    | 'SaveDevice'
    | 'SaveKey'
    | 'SaveKeychain'
    | 'SaveNotification'
    | 'SaveUser'
    | 'SecurityEventsFeed'
    | 'SendPasswordResetEmail'
    | 'Signup'
    | 'StripeUrl'
    | 'ToggleChildKeychain'
    | 'UpdateUnlockRequest'
    | 'UserActivityFeed'
    | 'UserActivitySummaries'
    | 'VerifySignupEmail',
  details: Record<string, any> = {},
): void {
  cy.intercept(`/pairql/dashboard/${slug}`, { __cyStubbedError: true, ...details });
}
