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
  slug: `CreateBillingPortalSession`,
  output: T.CreateBillingPortalSession.Output,
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
  slug: `LatestAppVersions`,
  output: T.LatestAppVersions.Output,
): void;
export function interceptPql(slug: `Login`, output: T.Login.Output): void;
export function interceptPql(
  slug: `LoginMagicLink`,
  output: T.LoginMagicLink.Output,
): void;
export function interceptPql(
  slug: `RequestMagicLink`,
  output: T.RequestMagicLink.Output,
): void;
export function interceptPql(slug: `ResetPassword`, output: T.ResetPassword.Output): void;
export function interceptPql(slug: `SaveDevice`, output: T.SaveDevice.Output): void;
export function interceptPql(slug: `SaveKey`, output: T.SaveKey.Output): void;
export function interceptPql(slug: `SaveKeychain`, output: T.SaveKeychain.Output): void;
export function interceptPql(
  slug: `SaveNotification`,
  output: T.SaveNotification.Output,
): void;
export function interceptPql(slug: `SaveUser`, output: T.SaveUser.Output): void;
export function interceptPql(
  slug: `SendPasswordResetEmail`,
  output: T.SendPasswordResetEmail.Output,
): void;
export function interceptPql(slug: `Signup`, output: T.Signup.Output): void;
export function interceptPql(
  slug: `UpdateSuspendFilterRequest`,
  output: T.UpdateSuspendFilterRequest.Output,
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
  const response = JSON.stringify(output) === `{}` ? `{}` : output;
  cy.intercept(`/pairql/dashboard/${slug}`, response).as(slug);
}

export function forcePqlErr(
  slug:
    | 'CombinedUsersActivityFeed'
    | 'CombinedUsersActivitySummaries'
    | 'ConfirmPendingNotificationMethod'
    | 'CreateBillingPortalSession'
    | 'CreatePendingAppConnection'
    | 'CreatePendingNotificationMethod'
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
    | 'LatestAppVersions'
    | 'Login'
    | 'LoginMagicLink'
    | 'RequestMagicLink'
    | 'ResetPassword'
    | 'SaveDevice'
    | 'SaveKey'
    | 'SaveKeychain'
    | 'SaveNotification'
    | 'SaveUser'
    | 'SendPasswordResetEmail'
    | 'Signup'
    | 'UpdateSuspendFilterRequest'
    | 'UpdateUnlockRequest'
    | 'UserActivityFeed'
    | 'UserActivitySummaries'
    | 'VerifySignupEmail',
  details: Record<string, any> = {},
): void {
  cy.intercept(`/pairql/dashboard/${slug}`, { __cyStubbedError: true, ...details });
}
