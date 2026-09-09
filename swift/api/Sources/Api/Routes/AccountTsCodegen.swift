import Foundation
import Gertie
import PairQL
import TypeScriptInterop

enum AccountTsCodegenRoute: PairQLTsCodegenRoute {
  static var logName: String {
    "Account".green
  }

  static var sharedAliases: [Config.Alias] {
    [
      .init(NoInput.self, as: "void"),
      .init(Date.self, as: "ISODateString"),
      .init(URL.self, as: "string"),
    ]
  }

  static var sharedTypes: [(String, Any.Type)] {
    [
      ("ServerPqlError", PqlError.self),
      ("SuccessOutput", SuccessOutput.self),
      ("ClientAuth", ClientAuth.self),
      ("ReleaseChannel", ReleaseChannel.self),
      ("ChildComputerStatus", ChildComputerStatus.self),
      ("PersonRelationship", Child.Relationship.self),
      ("SingleAppScope", AppScope.Single.self),
      ("AppScope", AppScope.self),
      ("SharedKey", Gertie.Key.self),
      ("BlockRule", Gertie.BlockRule.self),
      ("NotificationTrigger", Parent.Notification.Trigger.self),
      ("NotificationMethodConfig", Parent.NotificationMethod.Config.self),
      ("AccountNotification", GetAccountSettings.Notification.self),
      ("AccountNotificationMethod", GetAccountSettings.NotificationMethod.self),
      ("PlanStatus", PlanStatus.self),
      ("BillingStatus", BillingStatus.self),
      ("SubscriptionTier", StripeSubscription.Tier.self),
      ("SubscriptionPanelAction", GetSubscriptionPanel_v2.Action.self),
    ]
  }

  static var pairqlPairs: [any Pair.Type] {
    [
      AccountLogin.self,
      AccountRequestMagicLink.self,
      AccountLoginMagicLink.self,
      AccountSendPasswordResetEmail.self,
      AccountResetPassword.self,
      GetPeople.self,
      GetDevices.self,
      GetMacDevice.self,
      UpdateMacDevice.self,
      GetAccountSettings.self,
      CreateAccountNotificationMethod.self,
      ConfirmAccountNotificationMethod.self,
      SaveAccountNotification.self,
      DeleteAccountNotification.self,
      DeleteAccountNotificationMethod.self,
      SetAccountDailyReviewEmail.self,
      GetAccountBilling.self,
      StartAccountCheckout.self,
      OpenAccountBillingPortal.self,
      ChangeAccountSubscriptionTier.self,
      StartAccountFullTrial.self,
      HandleAccountCheckoutSuccess.self,
      HandleAccountCheckoutCancel.self,
      CreatePerson.self,
      UpdatePersonBasicDetails.self,
      DeletePerson.self,
      GetAccountKeychains.self,
      GetAccountKeychain.self,
      SaveAccountKey.self,
      DeleteAccountKey.self,
      SetAccountKeychainAssignment.self,
      GetPersonMacSettings.self,
      GetPersonInstalledMacApps.self,
      UpdatePersonMacMonitoringSettings.self,
      UpdatePersonMacInternetFiltering.self,
      UpdatePersonMacApps.self,
      GetIosDeviceSettings.self,
      UpdateIosDeviceBlockedGroups.self,
      UpdateIosDeviceProfileSettings.self,
      RequestPodcastsPinReset.self,
      RequestAccountPublicKeychain.self,
      GetSuspensionRequests.self,
      DecideSuspensionRequest.self,
      GetAccountUnlockRequestSummary.self,
      GetPersonUnlockRequests.self,
      DecideUnlockRequests.self,
      GetSecurityEvents.self,
      GetActivitySummaries.self,
      GetDayActivity.self,
      GetPersonActivitySummaries.self,
      GetPersonDayActivity.self,
      ToggleActivityFlag.self,
      DeleteActivity.self,
    ]
  }
}
