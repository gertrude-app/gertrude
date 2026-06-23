import DuetSQL
import PairQL
import Vapor

enum AuthedParentRoute: PairRoute {
  case confirmPendingNotificationMethod(ConfirmPendingNotificationMethod.Input)
  case createPendingNotificationMethod(CreatePendingNotificationMethod.Input)
  case dashboardWidgets_v2
  case dashboardWidgets_v3
  case decideFilterSuspensionRequest(DecideFilterSuspensionRequest.Input)
  case deleteActivityItems_v2(DeleteActivityItems_v2.Input)
  case deleteEntity_v2(DeleteEntity_v2.Input)
  case flagActivityItems(FlagActivityItems.Input)
  case getAccountOwnerV2
  case getAdminKeychain(GetAdminKeychain.Input)
  case getAdminKeychains
  case getAllDevices
  case getBatchUnlockRequestData(GetBatchUnlockRequestData.Input)
  case handleUnlockRequests(HandleUnlockRequests.Input)
  case getDevice(GetDevice.Input)
  case getIdentifiedApps
  case getSelectableKeychains
  case getSuspendFilterRequest(GetSuspendFilterRequest.Input)
  case getUnlockRequest(GetUnlockRequest.Input)
  case getUnlockRequests
  case getChild(GetChild.Input)
  case getChildren
  case searchMusicCatalog(SearchMusicCatalog.Input)
  case getApprovedMusicAlbums(GetApprovedMusicAlbums.Input)
  case approveMusicAlbum(ApproveMusicAlbum.Input)
  case removeApprovedMusicAlbum(RemoveApprovedMusicAlbum.Input)
  case handleCheckoutCancel(HandleCheckoutCancel.Input)
  case handleCheckoutSuccess(HandleCheckoutSuccess.Input)
  case iosDevice(IOSDevice.Id)
  case iosDevice_v2(IOSDevice.Id)
  case latestAppVersions
  case logEvent(LogEvent.Input)
  case userActivityFeed(UserActivityFeed.Input)
  case childActivitySummaries(ChildActivitySummaries.Input)
  case combinedUsersActivityFeed(CombinedUsersActivityFeed.Input)
  case familyActivitySummaries(FamilyActivitySummaries.Input)
  case getUserUnlockRequests(GetUserUnlockRequests.Input)
  case saveDevice(SaveDevice.Input)
  case saveKey(SaveKey.Input)
  case saveKeychain(SaveKeychain.Input)
  case saveNotification(SaveNotification.Input)
  case saveUser(SaveUser.Input)
  case setDailyReviewEmail(SetDailyReviewEmail.Input)
  case toggleChildKeychain(ToggleChildKeychain.Input)
  case getSubscriptionPanel
  case getSubscriptionPanel_v2
  case openBillingPortal(OpenBillingPortal.Input)
  case startCheckoutSession(StartCheckoutSession.Input)
  case securityEventsFeed
  case startFullTrial
  case changeSubscriptionTier(ChangeSubscriptionTier.Input)
  case updateUnlockRequest(UpdateUnlockRequest.Input)
  case requestPublicKeychain(RequestPublicKeychain.Input)
  case upsertBlockRule(UpsertBlockRule.Input)
  case updateIOSDevice(UpdateIOSDevice.Input)
  case claimIOSDevice(ClaimIOSDevice.Input)
  case getIOSDeviceClaimData(GetIOSDeviceClaimData.Input)
  case getAmClaimData(GetAmClaimData.Input)
  case claimAmDevice(ClaimAmDevice.Input)
  case getMusicClaimData(GetMusicClaimData.Input)
  case claimMusicDevice(ClaimMusicDevice.Input)
  case requestAmPinReset(RequestAmPinReset.Input)
  case getIOSDeviceSupervisionStatus(GetIOSDeviceSupervisionStatus.Input)
  case prepIOSAppConnection(PrepIOSAppConnection.Input)
  case iosAppConnectionCode(IOSAppConnectionCode.Input)
  case macAppConnectionCode(MacAppConnectionCode.Input)
}

extension AuthedParentRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, AuthedParentRoute> =
    OneOf {
      OneOf {
        Route(.case(Self.confirmPendingNotificationMethod)) {
          Operation(ConfirmPendingNotificationMethod.self)
          Body(.dashboardInput(ConfirmPendingNotificationMethod.self))
        }
        Route(.case(Self.createPendingNotificationMethod)) {
          Operation(CreatePendingNotificationMethod.self)
          Body(.dashboardInput(CreatePendingNotificationMethod.self))
        }
        Route(.case(Self.childActivitySummaries)) {
          Operation(ChildActivitySummaries.self)
          Body(.dashboardInput(ChildActivitySummaries.self))
        }
        Route(.case(Self.dashboardWidgets_v2)) {
          Operation(DashboardWidgets_v2.self)
        }
        Route(.case(Self.dashboardWidgets_v3)) {
          Operation(DashboardWidgets_v3.self)
        }
        Route(.case(Self.decideFilterSuspensionRequest)) {
          Operation(DecideFilterSuspensionRequest.self)
          Body(.dashboardInput(DecideFilterSuspensionRequest.self))
        }
        Route(.case(Self.deleteActivityItems_v2)) {
          Operation(DeleteActivityItems_v2.self)
          Body(.dashboardInput(DeleteActivityItems_v2.self))
        }
        Route(.case(Self.deleteEntity_v2)) {
          Operation(DeleteEntity_v2.self)
          Body(.dashboardInput(DeleteEntity_v2.self))
        }
        Route(.case(Self.familyActivitySummaries)) {
          Operation(FamilyActivitySummaries.self)
          Body(.dashboardInput(FamilyActivitySummaries.self))
        }
        Route(.case(Self.flagActivityItems)) {
          Operation(FlagActivityItems.self)
          Body(.dashboardInput(FlagActivityItems.self))
        }
        Route(.case(Self.getAccountOwnerV2)) {
          Operation(GetAccountOwner_v2.self)
        }
        Route(.case(Self.getAdminKeychain)) {
          Operation(GetAdminKeychain.self)
          Body(.dashboardInput(GetAdminKeychain.self))
        }
        Route(.case(Self.getAdminKeychains)) {
          Operation(GetAdminKeychains.self)
        }
        Route(.case(Self.getAllDevices)) {
          Operation(GetAllDevices.self)
        }
        Route(.case(Self.getDevice)) {
          Operation(GetDevice.self)
          Body(.dashboardInput(GetDevice.self))
        }
      }
      OneOf {
        Route(.case(Self.getIdentifiedApps)) {
          Operation(GetIdentifiedApps.self)
        }
        Route(.case(Self.getSelectableKeychains)) {
          Operation(GetSelectableKeychains.self)
        }
        Route(.case(Self.getSuspendFilterRequest)) {
          Operation(GetSuspendFilterRequest.self)
          Body(.dashboardInput(GetSuspendFilterRequest.self))
        }
        Route(.case(Self.getUnlockRequest)) {
          Operation(GetUnlockRequest.self)
          Body(.dashboardInput(GetUnlockRequest.self))
        }
        Route(.case(Self.getUnlockRequests)) {
          Operation(GetUnlockRequests.self)
        }
        Route(.case(Self.getChild)) {
          Operation(GetChild.self)
          Body(.dashboardInput(GetChild.self))
        }
        Route(.case(Self.getChildren)) {
          Operation(GetChildren.self)
        }
        Route(.case(Self.searchMusicCatalog)) {
          Operation(SearchMusicCatalog.self)
          Body(.dashboardInput(SearchMusicCatalog.self))
        }
        Route(.case(Self.getApprovedMusicAlbums)) {
          Operation(GetApprovedMusicAlbums.self)
          Body(.dashboardInput(GetApprovedMusicAlbums.self))
        }
        Route(.case(Self.approveMusicAlbum)) {
          Operation(ApproveMusicAlbum.self)
          Body(.dashboardInput(ApproveMusicAlbum.self))
        }
        Route(.case(Self.removeApprovedMusicAlbum)) {
          Operation(RemoveApprovedMusicAlbum.self)
          Body(.dashboardInput(RemoveApprovedMusicAlbum.self))
        }
        Route(.case(Self.handleCheckoutCancel)) {
          Operation(HandleCheckoutCancel.self)
          Body(.dashboardInput(HandleCheckoutCancel.self))
        }
        Route(.case(Self.handleCheckoutSuccess)) {
          Operation(HandleCheckoutSuccess.self)
          Body(.dashboardInput(HandleCheckoutSuccess.self))
        }
        Route(.case(Self.iosDevice)) {
          Operation(GetIOSDevice.self)
          Body(.dashboardInput(GetIOSDevice.self))
        }
        Route(.case(Self.iosDevice_v2)) {
          Operation(GetIOSDevice_v2.self)
          Body(.dashboardInput(GetIOSDevice_v2.self))
        }
        Route(.case(Self.logEvent)) {
          Operation(LogEvent.self)
          Body(.dashboardInput(LogEvent.self))
        }
        Route(.case(Self.userActivityFeed)) {
          Operation(UserActivityFeed.self)
          Body(.dashboardInput(UserActivityFeed.self))
        }
        Route(.case(Self.combinedUsersActivityFeed)) {
          Operation(CombinedUsersActivityFeed.self)
          Body(.dashboardInput(CombinedUsersActivityFeed.self))
        }
        Route(.case(Self.getBatchUnlockRequestData)) {
          Operation(GetBatchUnlockRequestData.self)
          Body(.dashboardInput(GetBatchUnlockRequestData.self))
        }
        Route(.case(Self.getUserUnlockRequests)) {
          Operation(GetUserUnlockRequests.self)
          Body(.dashboardInput(GetUserUnlockRequests.self))
        }
        Route(.case(Self.handleUnlockRequests)) {
          Operation(HandleUnlockRequests.self)
          Body(.dashboardInput(HandleUnlockRequests.self))
        }
        Route(.case(Self.latestAppVersions)) {
          Operation(LatestAppVersions.self)
        }
        Route(.case(Self.saveDevice)) {
          Operation(SaveDevice.self)
          Body(.dashboardInput(SaveDevice.self))
        }
      }
      OneOf {
        Route(.case(Self.saveKey)) {
          Operation(SaveKey.self)
          Body(.dashboardInput(SaveKey.self))
        }
        Route(.case(Self.saveKeychain)) {
          Operation(SaveKeychain.self)
          Body(.dashboardInput(SaveKeychain.self))
        }
        Route(.case(Self.saveNotification)) {
          Operation(SaveNotification.self)
          Body(.dashboardInput(SaveNotification.self))
        }
        Route(.case(Self.saveUser)) {
          Operation(SaveUser.self)
          Body(.dashboardInput(SaveUser.self))
        }
        Route(.case(Self.setDailyReviewEmail)) {
          Operation(SetDailyReviewEmail.self)
          Body(.dashboardInput(SetDailyReviewEmail.self))
        }
        Route(.case(Self.getSubscriptionPanel)) {
          Operation(GetSubscriptionPanel.self)
        }
        Route(.case(Self.getSubscriptionPanel_v2)) {
          Operation(GetSubscriptionPanel_v2.self)
        }
        Route(.case(Self.openBillingPortal)) {
          Operation(OpenBillingPortal.self)
          Body(.dashboardInput(OpenBillingPortal.self))
        }
        Route(.case(Self.startCheckoutSession)) {
          Operation(StartCheckoutSession.self)
          Body(.dashboardInput(StartCheckoutSession.self))
        }
        Route(.case(Self.changeSubscriptionTier)) {
          Operation(ChangeSubscriptionTier.self)
          Body(.dashboardInput(ChangeSubscriptionTier.self))
        }
        Route(.case(Self.securityEventsFeed)) {
          Operation(SecurityEventsFeed.self)
        }
        Route(.case(Self.startFullTrial)) {
          Operation(StartFullTrial.self)
        }
        Route(.case(Self.toggleChildKeychain)) {
          Operation(ToggleChildKeychain.self)
          Body(.dashboardInput(ToggleChildKeychain.self))
        }
        Route(.case(Self.updateUnlockRequest)) {
          Operation(UpdateUnlockRequest.self)
          Body(.dashboardInput(UpdateUnlockRequest.self))
        }
        Route(.case(Self.requestPublicKeychain)) {
          Operation(RequestPublicKeychain.self)
          Body(.dashboardInput(RequestPublicKeychain.self))
        }
        Route(.case(Self.upsertBlockRule)) {
          Operation(UpsertBlockRule.self)
          Body(.dashboardInput(UpsertBlockRule.self))
        }
        Route(.case(Self.updateIOSDevice)) {
          Operation(UpdateIOSDevice.self)
          Body(.dashboardInput(UpdateIOSDevice.self))
        }
        Route(.case(Self.claimIOSDevice)) {
          Operation(ClaimIOSDevice.self)
          Body(.dashboardInput(ClaimIOSDevice.self))
        }
        Route(.case(Self.getIOSDeviceClaimData)) {
          Operation(GetIOSDeviceClaimData.self)
          Body(.dashboardInput(GetIOSDeviceClaimData.self))
        }
        Route(.case(Self.getAmClaimData)) {
          Operation(GetAmClaimData.self)
          Body(.dashboardInput(GetAmClaimData.self))
        }
        Route(.case(Self.claimAmDevice)) {
          Operation(ClaimAmDevice.self)
          Body(.dashboardInput(ClaimAmDevice.self))
        }
        Route(.case(Self.getMusicClaimData)) {
          Operation(GetMusicClaimData.self)
          Body(.dashboardInput(GetMusicClaimData.self))
        }
        Route(.case(Self.claimMusicDevice)) {
          Operation(ClaimMusicDevice.self)
          Body(.dashboardInput(ClaimMusicDevice.self))
        }
        Route(.case(Self.requestAmPinReset)) {
          Operation(RequestAmPinReset.self)
          Body(.dashboardInput(RequestAmPinReset.self))
        }
        Route(.case(Self.getIOSDeviceSupervisionStatus)) {
          Operation(GetIOSDeviceSupervisionStatus.self)
          Body(.dashboardInput(GetIOSDeviceSupervisionStatus.self))
        }
        Route(.case(Self.prepIOSAppConnection)) {
          Operation(PrepIOSAppConnection.self)
          Body(.dashboardInput(PrepIOSAppConnection.self))
        }
        Route(.case(Self.iosAppConnectionCode)) {
          Operation(IOSAppConnectionCode.self)
          Body(.dashboardInput(IOSAppConnectionCode.self))
        }
        Route(.case(Self.macAppConnectionCode)) {
          Operation(MacAppConnectionCode.self)
          Body(.dashboardInput(MacAppConnectionCode.self))
        }
      }
    }
    .eraseToAnyParserPrinter()
}

extension AuthedParentRoute: RouteResponder {
  static func respond(to route: Self, in context: ParentContext) async throws -> Response {
    switch route {
    case .getChild(let input):
      let output = try await GetChild.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getChildren:
      let output = try await GetChildren.resolve(in: context)
      return try await self.respond(with: output)
    case .searchMusicCatalog(let input):
      let output = try await SearchMusicCatalog.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getApprovedMusicAlbums(let input):
      let output = try await GetApprovedMusicAlbums.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .approveMusicAlbum(let input):
      let output = try await ApproveMusicAlbum.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .removeApprovedMusicAlbum(let input):
      let output = try await RemoveApprovedMusicAlbum.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .saveUser(let input):
      let output = try await SaveUser.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .childActivitySummaries(let input):
      let output = try await ChildActivitySummaries.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .dashboardWidgets_v2:
      let output = try await DashboardWidgets_v2.resolve(in: context)
      return try await self.respond(with: output)
    case .dashboardWidgets_v3:
      let output = try await DashboardWidgets_v3.resolve(in: context)
      return try await self.respond(with: output)
    case .deleteEntity_v2(let input):
      let output = try await DeleteEntity_v2.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .familyActivitySummaries(let input):
      let output = try await FamilyActivitySummaries.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .decideFilterSuspensionRequest(let input):
      let output = try await DecideFilterSuspensionRequest.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .userActivityFeed(let input):
      let output = try await UserActivityFeed.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .combinedUsersActivityFeed(let input):
      let output = try await CombinedUsersActivityFeed.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getAccountOwnerV2:
      let output = try await GetAccountOwner_v2.resolve(in: context)
      return try await self.respond(with: output)
    case .logEvent(let input):
      let output = try await LogEvent.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .saveDevice(let input):
      let output = try await SaveDevice.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .saveNotification(let input):
      let output = try await SaveNotification.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .setDailyReviewEmail(let input):
      let output = try await SetDailyReviewEmail.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getIdentifiedApps:
      let output = try await GetIdentifiedApps.resolve(in: context)
      return try await self.respond(with: output)
    case .getAllDevices:
      let output = try await GetAllDevices.resolve(in: context)
      return try await self.respond(with: output)
    case .getDevice(let input):
      let output = try await GetDevice.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getSelectableKeychains:
      let output = try await GetSelectableKeychains.resolve(in: context)
      return try await self.respond(with: output)
    case .getAdminKeychains:
      let output = try await GetAdminKeychains.resolve(in: context)
      return try await self.respond(with: output)
    case .getAdminKeychain(let input):
      let output = try await GetAdminKeychain.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .handleCheckoutCancel(let input):
      let output = try await HandleCheckoutCancel.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .handleCheckoutSuccess(let input):
      let output = try await HandleCheckoutSuccess.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .iosDevice(let input):
      let output = try await GetIOSDevice.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .iosDevice_v2(let input):
      let output = try await GetIOSDevice_v2.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .latestAppVersions:
      let output = try await LatestAppVersions.resolve(in: context)
      return try await self.respond(with: output)
    case .saveKeychain(let input):
      let output = try await SaveKeychain.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .confirmPendingNotificationMethod(let input):
      let output = try await ConfirmPendingNotificationMethod.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getUnlockRequest(let input):
      let output = try await GetUnlockRequest.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getUnlockRequests:
      let output = try await GetUnlockRequests.resolve(in: context)
      return try await self.respond(with: output)
    case .getBatchUnlockRequestData(let input):
      let output = try await GetBatchUnlockRequestData.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getUserUnlockRequests(let input):
      let output = try await GetUserUnlockRequests.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .handleUnlockRequests(let input):
      let output = try await HandleUnlockRequests.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getSuspendFilterRequest(let input):
      let output = try await GetSuspendFilterRequest.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .createPendingNotificationMethod(let input):
      let output = try await CreatePendingNotificationMethod.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .updateUnlockRequest(let input):
      let output = try await UpdateUnlockRequest.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .saveKey(let input):
      let output = try await SaveKey.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getSubscriptionPanel:
      let output = try await GetSubscriptionPanel.resolve(in: context)
      return try await self.respond(with: output)
    case .getSubscriptionPanel_v2:
      let output = try await GetSubscriptionPanel_v2.resolve(in: context)
      return try await self.respond(with: output)
    case .openBillingPortal(let input):
      let output = try await OpenBillingPortal.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .startCheckoutSession(let input):
      let output = try await StartCheckoutSession.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .changeSubscriptionTier(let input):
      let output = try await ChangeSubscriptionTier.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .securityEventsFeed:
      let output = try await SecurityEventsFeed.resolve(in: context)
      return try await self.respond(with: output)
    case .startFullTrial:
      let output = try await StartFullTrial.resolve(in: context)
      return try await self.respond(with: output)
    case .toggleChildKeychain(let input):
      let output = try await ToggleChildKeychain.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .deleteActivityItems_v2(let input):
      let output = try await DeleteActivityItems_v2.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .requestPublicKeychain(let input):
      let output = try await RequestPublicKeychain.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .flagActivityItems(let input):
      let output = try await FlagActivityItems.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .upsertBlockRule(let input):
      let output = try await UpsertBlockRule.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .updateIOSDevice(let input):
      let output = try await UpdateIOSDevice.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .claimIOSDevice(let input):
      let output = try await ClaimIOSDevice.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getIOSDeviceClaimData(let input):
      let output = try await GetIOSDeviceClaimData.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getAmClaimData(let input):
      let output = try await GetAmClaimData.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .claimAmDevice(let input):
      let output = try await ClaimAmDevice.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getMusicClaimData(let input):
      let output = try await GetMusicClaimData.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .claimMusicDevice(let input):
      let output = try await ClaimMusicDevice.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .requestAmPinReset(let input):
      let output = try await RequestAmPinReset.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getIOSDeviceSupervisionStatus(let input):
      let output = try await GetIOSDeviceSupervisionStatus.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .prepIOSAppConnection(let input):
      let output = try await PrepIOSAppConnection.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .iosAppConnectionCode(let input):
      let output = try await IOSAppConnectionCode.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .macAppConnectionCode(let input):
      let output = try await MacAppConnectionCode.resolve(with: input, in: context)
      return try await self.respond(with: output)
    }
  }
}
