import Foundation
import Gertie
import GertieBlocker
import MusicRoute
import PairQL
import PodcastRoute
import Tagged
import TypeScriptInterop

enum DashboardTsCodegenRoute: PairQLTsCodegenRoute {
  static var logName: String {
    "Dashboard".green
  }

  static var sharedAliases: [Config.Alias] {
    [
      .init(NoInput.self, as: "void"),
      .init(Infallible.self, as: "void"),
      .init(Date.self, as: "ISODateString"),
      .init(StripeSubscription.StripeId.self, as: "string"),
      .init(URL.self, as: "string"),
      .init(Music.AlbumId.self, as: "string"),
      .init(Music.ArtistId.self, as: "string"),
      .init(Music.TrackId.self, as: "string"),
    ]
  }

  static var sharedTypes: [(String, Any.Type)] {
    [
      ("ServerPqlError", PqlError.self),
      ("ReleaseChannel", ReleaseChannel.self),
      ("SingleAppScope", AppScope.Single.self),
      ("AppScope", AppScope.self),
      ("SharedKey", Gertie.Key.self),
      ("Key", GetAdminKeychains.Key.self),
      ("SuccessOutput", SuccessOutput.self),
      ("ClientAuth", ClientAuth.self),
      ("DeviceModelFamily", DeviceModelFamily.self),
      ("RequestStatus", RequestStatus.self),
      ("UnlockRequest", GetBatchUnlockRequestData.UnlockRequestData.self),
      ("KeychainSummary", KeychainSummary.self),
      ("ChildComputerStatus", ChildComputerStatus.self),
      ("ChildComputer", GetChild.Computer.self),
      ("ChildIOSDevice", GetChild.IOSDevice.self),
      ("Device", GetDevice.Output.self),
      ("PlainTime", PlainTime.self),
      ("PlainTimeWindow", PlainTimeWindow.self),
      ("RuleSchedule", RuleSchedule.self),
      ("BlockedMacApp", BlockedMacApp.DTO.self),
      ("UnrestrictedMacApp", UnrestrictedMacApp.DTO.self),
      ("PublicUnrestrictedMacApp", PublicUnrestrictedMacApp.self),
      ("UserKeychainSummary", UserKeychainSummary.self),
      ("BlockRule", GertieBlocker.BlockRule.self),
      ("Child", GetChild.Child.self),
      ("SuspendFilterRequest", GetSuspendFilterRequest.Output.self),
      ("AdminKeychain", GetAdminKeychains.AdminKeychain.self),
      ("UserActivityItem", UserActivity.Item.self),
      ("AdminNotificationTrigger", Parent.Notification.Trigger.self),
      ("VerifiedNotificationMethod", GetAccountOwner_v2.VerifiedNotificationMethod.self),
      ("AdminNotification", GetAccountOwner_v2.Notification.self),
      ("WebPolicy", WebContentFilterPolicy.Kind.self),
      ("SecurityEventSeverity", SecurityEventsFeed.Severity.self),
      ("PaidSubscription", PaidSubscription.self),
      ("PlanStatus", PlanStatus.self),
      ("BillingStatus", BillingStatus.self),
      ("SubscriptionTier", StripeSubscription.Tier.self),
      ("SubscriptionPanelAction", GetSubscriptionPanel_v2.Action.self),
      ("AmSubscriptionState", AmSubscriptionState.self),
      ("MusicSubscriptionState", MusicSubscriptionState.self),
      ("IOSDeviceChildAssignment", ClaimIOSDevice.ChildAssignment.self),
      ("ClaimChildOption", GetIOSDeviceClaimData.ChildOption.self),
      ("ExtendedSupervisionControls", SaveExtendedSupervisionControls.Controls.self),
      ("AllowListBookmark", SaveExtendedSupervisionControls.Bookmark.self),
    ]
  }

  static var pairqlPairs: [any Pair.Type] {
    [
      UserActivityFeed.self,
      GetAccountOwner_v2.self,
      ConfirmPendingNotificationMethod.self,
      CreatePendingNotificationMethod.self,
      DashboardWidgets_v3.self,
      DeleteActivityItems_v2.self,
      DeleteEntity_v2.self,
      GetAdminKeychain.self,
      GetAdminKeychains.self,
      GetDevice.self,
      GetIdentifiedApps.self,
      GetSelectableKeychains.self,
      GetSuspendFilterRequest.self,
      GetBatchUnlockRequestData.self,
      HandleUnlockRequests.self,
      GetChild.self,
      GetInstalledMacApps.self,
      GetChildren.self,
      SearchMusicCatalog_v2.self,
      GetMusicCuration.self,
      GetMusicAlbumCuration.self,
      SaveMusicAlbumCuration.self,
      ApproveMusicTrack.self,
      ApproveMusicAlbum_v2.self,
      ApproveMusicArtist_v2.self,
      RemoveApprovedMusicArtist.self,
      HandleCheckoutCancel.self,
      HandleCheckoutSuccess.self,
      LatestAppVersions.self,
      UserActivityFeed.self,
      CombinedUsersActivityFeed.self,
      ChildActivitySummaries.self,
      FamilyActivitySummaries.self,
      Login.self,
      LoginMagicLink.self,
      LogEvent.self,
      RequestMagicLink.self,
      ResetPassword.self,
      SaveDevice.self,
      SaveKey.self,
      SaveKeychain.self,
      SaveNotification.self,
      SaveUser.self,
      SaveMacappMonitoring.self,
      SaveMacappApps.self,
      SaveMacappFiltering.self,
      SetDailyReviewEmail.self,
      SendPasswordResetEmail.self,
      Signup.self,
      GetSubscriptionPanel_v2.self,
      OpenBillingPortal.self,
      StartCheckoutSession.self,
      ChangeSubscriptionTier.self,
      ToggleChildKeychain.self,
      DecideFilterSuspensionRequest.self,
      VerifySignupEmail.self,
      SaveConferenceEmail.self,
      SecurityEventsFeed.self,
      StartFullTrial.self,
      RequestPublicKeychain.self,
      FlagActivityItems.self,
      GetIOSDevice_v3.self,
      UpsertBlockRule.self,
      UpdateIOSDevice.self,
      SaveExtendedSupervisionControls.self,
      GetIOSDeviceClaimData.self,
      GetAmClaimData.self,
      ClaimAmDevice.self,
      GetMusicClaimData.self,
      ClaimMusicDevice.self,
      GetBlockerClaimData.self,
      ClaimBlockerDevice.self,
      RequestAmPinReset.self,
      ClaimIOSDevice.self,
      GetIOSDeviceSupervisionStatus.self,
      MacAppConnectionCode.self,
      PrepIOSAppConnection.self,
      IOSAppConnectionCode.self,
      GetAllDevices.self,
    ]
  }
}

// extensions

extension Tagged: @retroactive TypeScriptAliased where RawValue == UUID {
  public static var typescriptAlias: String {
    "UUID"
  }
}
