import Gertie
import GertieIOS
import PairQL
import Tagged
import TypeScriptInterop
import Vapor

enum DashboardTsCodegenRoute {
  struct Response: Content {
    struct Pair: Content {
      let pair: String
      let fetcher: String
    }

    var shared: [String: String]
    var pairs: [String: Pair]
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
      ("UnlockRequest", GetUnlockRequest.Output.self),
      ("KeychainSummary", KeychainSummary.self),
      ("ChildComputerStatus", ChildComputerStatus.self),
      ("ChildComputer", GetChild.Computer.self),
      ("ChildIOSDevice", GetChild.IOSDevice.self),
      ("Device", GetDevice.Output.self),
      ("PlainTime", PlainTime.self),
      ("PlainTimeWindow", PlainTimeWindow.self),
      ("RuleSchedule", RuleSchedule.self),
      ("BlockedApp", UserBlockedApp.DTO.self),
      ("UserKeychainSummary", UserKeychainSummary.self),
      ("Child", GetChild.Child.self),
      ("SuspendFilterRequest", GetSuspendFilterRequest.Output.self),
      ("AdminKeychain", GetAdminKeychains.AdminKeychain.self),
      ("UserActivityItem", UserActivity.Item.self),
      ("AdminNotificationTrigger", Parent.Notification.Trigger.self),
      ("VerifiedNotificationMethod", GetAccountOwner.VerifiedNotificationMethod.self),
      ("AdminNotification", GetAccountOwner.Notification.self),
      ("WebPolicy", WebContentFilterPolicy.Kind.self),
      ("BlockRule", GertieIOS.BlockRule.self),
      ("SecurityEventSeverity", SecurityEventsFeed.Severity.self),
      ("Plan", Plan.self),
    ]
  }

  static var pairqlPairs: [any Pair.Type] {
    [
      UserActivityFeed.self,
      GetAccountOwner.self,
      ConfirmPendingNotificationMethod.self,
      CreatePendingAppConnection.self,
      CreatePendingNotificationMethod.self,
      DashboardWidgets.self,
      DeleteActivityItems_v2.self,
      DeleteEntity_v2.self,
      GetAdminKeychain.self,
      GetAdminKeychains.self,
      GetDevice.self,
      GetDevices.self,
      GetIdentifiedApps.self,
      GetSelectableKeychains.self,
      GetSuspendFilterRequest.self,
      GetUnlockRequest.self,
      GetUnlockRequests.self,
      GetChild.self,
      GetChildren.self,
      HandleCheckoutCancel.self,
      HandleCheckoutSuccess.self,
      LatestAppVersions.self,
      UserActivityFeed.self,
      CombinedUsersActivityFeed.self,
      ChildActivitySummaries.self,
      FamilyActivitySummaries.self,
      GetUserUnlockRequests.self,
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
      SendPasswordResetEmail.self,
      Signup.self,
      StripeUrl.self,
      ToggleChildKeychain.self,
      DecideFilterSuspensionRequest.self,
      UpdateUnlockRequest.self,
      VerifySignupEmail.self,
      SaveConferenceEmail.self,
      SecurityEventsFeed.self,
      RequestPublicKeychain.self,
      FlagActivityItems.self,
      IOSDevices.self,
      GetIOSDevice.self,
      UpsertBlockRule.self,
      UpdateIOSDevice.self,
      GetClaimDeviceData.self,
      ClaimSupervisionCode.self,
      GetSupervisionDeviceStatus.self,
    ]
  }

  @Sendable static func handler(_ request: Request) async throws -> Response {
    request.logger.notice("TS codegen: \("Dashboard".green)")
    var shared: [String: String] = [:]
    var sharedAliases: [Config.Alias] = [
      .init(NoInput.self, as: "void"),
      .init(Date.self, as: "ISODateString"),
      .init(Subscription.StripeId.self, as: "string"),
    ]
    var config = Config(compact: true, aliasing: sharedAliases)

    for (name, type) in self.sharedTypes {
      shared[name] = try CodeGen(config: config).declaration(for: type, as: name)
      sharedAliases.append(.init(type, as: name))
      config = .init(compact: true, aliasing: sharedAliases)
    }

    var pairs: [String: Response.Pair] = [:]
    for pairType in self.pairqlPairs {
      pairs[pairType.name] = try self.ts(for: pairType, with: config)
    }

    return Response(shared: shared, pairs: pairs)
  }

  private static func ts<P: Pair>(
    for type: P.Type,
    with config: Config,
  ) throws -> Response.Pair {
    let codegen = CodeGen(config: config)
    let name = "\(P.self)"
    var pair = try """
    export namespace \(name) {
      \(codegen.declaration(for: P.Input.self, as: "Input"))

      \(codegen.declaration(for: P.Output.self, as: "Output"))
    }
    """

    // pairs that are only typealiases get compacted more
    let pairLines = pair.split(separator: "\n")
    if pairLines.count == 4, pairLines.allSatisfy({ $0.count < 60 }) {
      pair = pairLines.joined(separator: "\n")
    }

    var fetchName = "\(name)".regexReplace("_.*$", "")
    let firstLetter = fetchName.removeFirst()
    let functionName = String(firstLetter).lowercased() + fetchName

    let fetcher = """
    \(functionName) = (input: P.\(name).Input): Promise<Result<P.\(name).Output>> => {
      return this.query<P.\(name).Output>(input, `\(P.name)`, `\(P.auth)`);
    }
    """
    return .init(pair: pair, fetcher: fetcher)
  }
}

// extensions

extension Tagged: @retroactive TypeScriptAliased where RawValue == UUID {
  public static var typescriptAlias: String {
    "UUID"
  }
}
