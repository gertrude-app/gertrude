import ComposableArchitecture
import Foundation
import GertieTcaFeatures
import IOSRoute
import LibClients
import LibCore
import os.log

@_exported import GertieBlocker
@_exported import PairQL
@_exported import XCore

@Reducer
public struct IOSReducer {
  struct Deps: Sendable {
    @Dependency(\.api) var api
    @Dependency(\.appStore) var appStore
    @Dependency(\.continuousClock) var clock
    @Dependency(\.device) var device
    @Dependency(\.filter) var filter
    @Dependency(\.systemExtension) var systemExtension
    @Dependency(\.sharedStorage) var sharedStorage
    @Dependency(\.date.now) var now
    @Dependency(\.locale) var locale
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.keychain) var keychain
  }

  @ObservationIgnored
  let deps = Deps()

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .interactive(let interactiveAction):
        self.interactive(state: &state, action: interactiveAction)
      case .programmatic(let programmaticAction):
        self.programmatic(state: &state, action: programmaticAction)
      case .destination(.presented(let destinationAction)):
        self.destination(state: &state, action: destinationAction)
      case .destination(.dismiss):
        if state.destination?.crossPromo != nil {
          self.closeCrossPromo(&state, event: .dismiss, ctaSlot: nil)
        } else {
          .none
        }
      case .destination:
        .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
    .ifLet(\.onboarding.clearCache, action: \.interactive.onboardingClearCache) {
      ClearCacheFeature()
    }
    .ifLet(\.onboarding.crossPromo, action: \.interactive.onboardingCrossPromo) {
      CrossPromoFeature()
    }
    .ifLet(\.onboarding.connect, action: \.interactive.onboardingConnect) {
      ConnectAccount()
    }
  }

  func interactive(state: inout State, action: Action.Interactive) -> EffectOf<IOSReducer> {
    switch action {
    case .onboardingBtnTapped(let btn, _):
      return self.onboardingBtnTapped(btn, state: &state, action: action)

    case .blockGroupToggled(let groupId):
      self.deps.log("block group toggled: \(groupId)", "02976f9b")
      if state.disabledBlockGroupIds.contains(groupId) {
        state.disabledBlockGroupIds.removeAll { $0 == groupId }
      } else {
        state.disabledBlockGroupIds.append(groupId)
      }
      return .none

    case .sheetDismissed:
      return .none

    case .infoBtnTapped:
      state.destination = .info(.init(
        connection: self.deps.sharedStorage.loadAccountConnection(),
        // TODO: should async call device.deviceId() instead
        deviceId: self.deps.keychain.loadVendorId(),
        numRules: self.deps.sharedStorage.loadProtectionMode()?.rules?.count ?? 0,
        numDisabledBlockGroups: self.deps.sharedStorage.loadDisabledBlockGroupIds()?.count ?? 0,
        numTotalBlockGroups: state.allBlockGroups.isEmpty ? 9 : state.allBlockGroups.count,
      ))
      return .none

    #if DEBUG
      case .receivedShake where state.screen == .onboarding(.happyPath(.hiThere)):
        state.screen = .onboarding(.happyPath(.dontGetTrickedPreAuth))
        return .none
    #endif

    case .onboardingClearCache(.completeBtnTapped),
         .onboardingClearCache(.receivedClearCacheUpdate(.errorCouldNotCreateDir)):
      state.onboarding.clearCache = nil
      if state.screen == .onboarding(.supervision(.resume(.promptClearCache))) {
        state.screen = .onboarding(.happyPath(.requestAppStoreRating))
        return .run { [deps = self.deps] _ in
          deps.sharedStorage.clearPendingSupervisionCode()
        }
      } else {
        state.screen = .onboarding(.happyPath(.requestAppStoreRating))
        return .none
      }

    case .onboardingClearCache:
      return .none

    case .onboardingCrossPromo(.delegate(.ctaTapped(let slot))):
      return self.closeOnboardingCrossPromo(&state, event: .cta, ctaSlot: slot)

    case .onboardingCrossPromo(.delegate(.dismissed)):
      return self.closeOnboardingCrossPromo(&state, event: .dismiss, ctaSlot: nil)

    case .onboardingCrossPromo:
      return .none

    case .onboardingConnect(.connectionSucceeded(childData: let conn)):
      state.onboarding.connect = nil
      state.screen = .onboarding(.happyPath(.connectSuccess))
      self.deps.sharedStorage.clearPendingSupervisionCode()
      return .run { [deps = self.deps] _ in
        await deps.receiveAccountConnection(conn)
      }

    case .onboardingConnect(.cancelTapped):
      state.onboarding.connect = nil
      return .none

    case .onboardingConnect:
      return .none

    case .receivedShake:
      return .none
    }
  }

  func onboardingBtnTapped(
    _ btn: Action.Interactive.OnboardingBtn,
    state: inout State,
    action: Action.Interactive,
  ) -> EffectOf<IOSReducer> {
    switch (state.screen, btn) {
    case (.onboarding(.happyPath(.hiThere)), .primary):
      self.deps.log(state.screen, action, "6f97eb1b")
      state.screen = .onboarding(.happyPath(.timeExpectation))
      return .none

    case (.onboarding(.happyPath(.timeExpectation)), .primary):
      self.deps.log(state.screen, action, "762bf9bf")
      state.screen = .onboarding(.happyPath(.confirmChildsDevice))
      return .none

    case (.onboarding(.happyPath(.confirmChildsDevice)), .primary):
      self.deps.log(state.screen, action, "666d5e0f")
      state.screen = .onboarding(.happyPath(.explainPermissionDependsOnAge))
      return .none

    case (.onboarding(.happyPath(.explainPermissionDependsOnAge)), .primary):
      self.deps.log(state.screen, action, "a8f633ca")
      state.screen = .onboarding(.happyPath(.confirmMinorDevice))
      return .none

    case (.onboarding(.happyPath(.confirmChildsDevice)), .secondary):
      self.deps.log(state.screen, action, "30fac4e6")
      state.screen = .onboarding(.onParentDeviceFail)
      return .none

    case (.onboarding(.happyPath(.confirmMinorDevice)), .primary):
      self.deps.log(state.screen, action, "e17137b0")
      state.screen = .onboarding(.happyPath(.confirmParentIsOnboarding))
      return .none

    case (.onboarding(.happyPath(.confirmMinorDevice)), .secondary):
      self.deps.log(state.screen, action, "a21c9040")
      if self.isBuildAhead(of: state.onboarding.connectFeature.releasedAppStoreVersion) {
        state.screen = .onboarding(.mdmSupervisionExplainer)
      } else {
        state.screen = .onboarding(.supervision(.setup(.adultNeedsSupervision)))
      }
      return .none

    case (.onboarding(.happyPath(.confirmParentIsOnboarding)), .primary):
      self.deps.log(state.screen, action, "51611498")
      state.screen = .onboarding(.happyPath(.confirmInAppleFamily))
      return .none

    case (.onboarding(.happyPath(.confirmInAppleFamily)), .primary):
      self.deps.log(state.screen, action, "7d0fd46e")
      state.screen = .onboarding(.happyPath(.explainTwoInstallSteps))
      return .none

    case (.onboarding(.happyPath(.confirmInAppleFamily)), .secondary):
      self.deps.log(state.screen, action, "daa8c7fd")
      state.screen = .onboarding(.appleFamily(.explainRequiredForFiltering))
      return .none

    case (.onboarding(.happyPath(.confirmInAppleFamily)), .tertiary):
      self.deps.log(state.screen, action, "232fb200")
      state.screen = .onboarding(.appleFamily(.explainWhatIsAppleFamily))
      return .none

    case (.onboarding(.happyPath(.confirmParentIsOnboarding)), .secondary):
      self.deps.log(state.screen, action, "3c4772ad")
      state.screen = .onboarding(.childIsOnboardingFail)
      return .none

    case (.onboarding(.happyPath(.explainTwoInstallSteps)), .primary):
      self.deps.log(state.screen, action, "6582656c")
      state.screen = .onboarding(.happyPath(.explainAuthWithParentAppleAccount))
      return .none

    case (.onboarding(.happyPath(.explainAuthWithParentAppleAccount)), .primary):
      self.deps.log(state.screen, action, "5d3a5ba2")
      state.screen = .onboarding(.happyPath(.dontGetTrickedPreAuth))
      return .none

    case (.onboarding(.happyPath(.dontGetTrickedPreAuth)), .primary):
      self.deps.log(state.screen, action, "87601352")
      return .run { [deps = self.deps] send in
        switch await deps.systemExtension.requestAuthorization() {
        case .success:
          await send(.programmatic(.authorizationSucceeded))
          await deps.api.logEvent("4a0c585f", "[onboarding] authorization succeeded")
        case .failure(let reason):
          await send(.programmatic(.authorizationFailed(reason)))
          await deps.systemExtension.cleanupForRetry()
          await deps.api.logEvent("e2e02460", "[onboarding] authorization failed: \(reason)")
        }
      }

    case (.onboarding(.happyPath(.explainInstallWithDevicePasscode)), .primary):
      self.deps.log(state.screen, action, "5dcaa641")
      state.screen = .onboarding(.happyPath(.dontGetTrickedPreInstall))
      return .none

    case (.onboarding(.happyPath(.dontGetTrickedPreInstall)), .primary):
      self.deps.log(state.screen, action, "47bee21e")
      return .run { [deps = self.deps] send in
        switch await deps.systemExtension.installFilter() {
        case .success:
          await send(.programmatic(.installSucceeded))
          await deps.api.logEvent("adced334", "[onboarding] filter install success")
        case .failure(let error):
          await send(.programmatic(.installFailed(error)))
          await deps.systemExtension.cleanupForRetry()
          await deps.api.logEvent("004d0d89", "[onboarding] filter install failed: \(error)")
        }
      }

    case (.onboarding(.happyPath(.offerAccountConnect)), .primary):
      self.deps.log(state.screen, action, "b93bb543")
      state.onboarding.connect = .init()
      return .none

    case (.onboarding(.happyPath(.offerAccountConnect)), .secondary):
      self.deps.log(state.screen, action, "62b6a262")
      return self.transitionToOptOutOrSkip(state: &state)

    case (.onboarding(.happyPath(.offerAccountConnect)), .tertiary):
      self.deps.log(state.screen, action, "f4986227")
      state.screen = .onboarding(.happyPath(.explainAccountConnect))
      return .none

    case (.onboarding(.happyPath(.explainAccountConnect)), .primary):
      self.deps.log(state.screen, action, "0d00951c")
      state.screen = .onboarding(.happyPath(.offerAccountConnect))
      return .none

    case (.onboarding(.happyPath(.connectSuccess)), .primary):
      self.deps.log(state.screen, action, "63d34e4c")
      state.screen = .onboarding(.happyPath(.promptClearCache))
      return .none

    case (.onboarding(.happyPath(.optOutBlockGroups)), .primary):
      self.deps.log(state.screen, action, "cdb31095")
      if !state.allBlockGroups.isEmpty,
         state.allBlockGroups.allSatisfy({ state.disabledBlockGroupIds.contains($0.id) }) {
        return .none
      }
      state.screen = .onboarding(.happyPath(.promptClearCache))
      return .merge(
        .run { [deps = self.deps, disabled = state.disabledBlockGroupIds] _ in
          deps.sharedStorage.saveDisabledBlockGroupIds(disabled)
          if let deviceId = await deps.device.deviceId() {
            let result = try? await deps.api.fetchBlockRules(
              deviceId: deviceId,
              disabledGroups: disabled,
            )
            if let rules = result, !rules.isEmpty {
              deps.sharedStorage.saveProtectionMode(.normal(rules))
            }
          } else {
            deps.log("UNEXPECTED no vendor id on opt out", "d9e93a4b")
          }
          // NB: safeguard so we don't ever end up with empty rules
          if deps.sharedStorage.loadProtectionMode().missingRules {
            deps.log("UNEXPECTED missing rules after opt-out", "ffff30ac")
            deps.sharedStorage.saveProtectionMode(.normal(BlockRule.Legacy.defaults.map(\.current)))
          }
        },
      )

    case (.onboarding(.happyPath(.promptClearCache)), .primary):
      self.deps.log(state.screen, action, "8a8a3033")
      state.onboarding.clearCache = .init(context: .onboarding)
      return .none

    case (.onboarding(.happyPath(.promptClearCache)), .secondary):
      self.deps.log(state.screen, action, "1221f1a3")
      state.screen = .onboarding(.happyPath(.requestAppStoreRating))
      return .none

    case (.onboarding(.happyPath(.requestAppStoreRating)), .primary):
      self.deps.log(state.screen, action, "4fc0b1bf")
      return .merge(
        .run { [deps = self.deps] _ in await deps.appStore.requestRating() },
        self.presentOnboardingCrossPromo(&state),
      )

    case (.onboarding(.happyPath(.requestAppStoreRating)), .secondary):
      self.deps.log(state.screen, action, "a9480aa2")
      return .merge(
        .run { [deps = self.deps] _ in await deps.appStore.requestReview() },
        self.presentOnboardingCrossPromo(&state),
      )

    case (.onboarding(.happyPath(.requestAppStoreRating)), .tertiary):
      self.deps.log(state.screen, action, "0dddc87c")
      return self.presentOnboardingCrossPromo(&state)

      // MARK: - apple family

    case (.onboarding(.appleFamily(.explainRequiredForFiltering)), .primary):
      self.deps.log(state.screen, action, "97a57eb2")
      state.screen = .onboarding(.appleFamily(.explainSetupFreeAndEasy))
      return .none

    case (.onboarding(.appleFamily(.explainSetupFreeAndEasy)), .primary):
      self.deps.log(state.screen, action, "2badbcb8")
      state.screen = .onboarding(.appleFamily(.howToSetupAppleFamily))
      return .none

    case (.onboarding(.appleFamily(.checkIfInAppleFamily)), .primary):
      self.deps.log(state.screen, action, "07cac029")
      state.screen = state.onboarding
        .takeReturningTo() ?? .onboarding(.happyPath(.confirmInAppleFamily))
      return .none

    case (.onboarding(.appleFamily(.checkIfInAppleFamily)), .secondary):
      self.deps.log(state.screen, action, "b311a78a")
      state.screen = .onboarding(.appleFamily(.explainSetupFreeAndEasy))
      return .none

    case (.onboarding(.appleFamily(.howToSetupAppleFamily)), .tertiary):
      self.deps.log(state.screen, action, "548e81b6")
      state.screen = .onboarding(.happyPath(.confirmInAppleFamily))
      state.onboarding.returningTo = nil
      return .none

    case (.onboarding(.appleFamily(.explainWhatIsAppleFamily)), .primary):
      self.deps.log(state.screen, action, "1c495932")
      state.screen = .onboarding(.appleFamily(.checkIfInAppleFamily))
      return .none

      // MARK: - supervision setup

    case (.onboarding(.supervision(.setup(.adultNeedsSupervision))), .primary):
      self.deps.log(state.screen, action, "f214328e")
      state.screen = .onboarding(.supervision(.setup(.whatIsSupervisedMode)))
      return .none

    case (.onboarding(.supervision(.setup(.whatIsSupervisedMode))), .primary):
      self.deps.log(state.screen, action, "5dcda279")
      state.screen = .onboarding(.supervision(.setup(.supervisedDeviceReassurance)))
      return .none

    case (.onboarding(.supervision(.setup(.supervisedDeviceReassurance))), .primary):
      self.deps.log(state.screen, action, "e002ad70")
      state.screen = .onboarding(.supervision(.setup(.explainSupervision)))
      return .none

    case (.onboarding(.supervision(.setup(.explainSupervision))), .primary):
      self.deps.log(state.screen, action, "261ba66b")
      state.screen = .onboarding(.supervision(.setup(.costAndBranchPoint)))
      return .none

    case (.onboarding(.supervision(.setup(.costAndBranchPoint))), .primary):
      self.deps.log(state.screen, action, "a0f78c2c")
      state.screen = .onboarding(.supervision(.setup(.explainNeedSomeoneElse)))
      return .none

    case (.onboarding(.supervision(.setup(.costAndBranchPoint))), .secondary):
      self.deps.log(state.screen, action, "7023c325")
      state.screen = .onboarding(.supervision(.setup(.freeAlternativesHub)))
      return .none

    case (.onboarding(.supervision(.setup(.freeAlternativesHub))), .primary):
      self.deps.log(state.screen, action, "422d0980")
      state.screen = .onboarding(.supervision(.setup(.birthdayAlternativeExplain)))
      return .none

    case (.onboarding(.supervision(.setup(.freeAlternativesHub))), .secondary):
      self.deps.log(state.screen, action, "a5229ef2")
      state.screen = .onboarding(.supervision(.setup(.siblingAlternativeExplain)))
      return .none

    case (.onboarding(.supervision(.setup(.freeAlternativesHub))), .tertiary):
      self.deps.log(state.screen, action, "ed672bfe")
      state.screen = .onboarding(.supervision(.setup(.appleConfiguratorExplain)))
      return .none

    case (.onboarding(.supervision(.setup(.freeAlternativesHub))), .quaternary):
      self.deps.log(state.screen, action, "7bbba656")
      state.screen = .onboarding(.supervision(.setup(.explainNeedSomeoneElse)))
      return .none

    case (.onboarding(.supervision(.setup(.birthdayAlternativeExplain))), .primary):
      self.deps.log(state.screen, action, "4c9db46e")
      state.screen = .onboarding(.supervision(.setup(.birthdayAlternativeCons)))
      return .none

    case (.onboarding(.supervision(.setup(.birthdayAlternativeExplain))), .secondary):
      self.deps.log(state.screen, action, "359543af")
      state.screen = .onboarding(.supervision(.setup(.freeAlternativesHub)))
      return .none

    case (.onboarding(.supervision(.setup(.birthdayAlternativeCons))), .primary):
      self.deps.log(state.screen, action, "d567937a")
      state.screen = .onboarding(.supervision(.setup(.birthdayAlternativeInstructions)))
      return .none

    case (.onboarding(.supervision(.setup(.birthdayAlternativeCons))), .secondary):
      self.deps.log(state.screen, action, "b1c2d3e4")
      state.screen = .onboarding(.supervision(.setup(.freeAlternativesHub)))
      return .none

    case (.onboarding(.supervision(.setup(.birthdayAlternativeInstructions))), .primary):
      self.deps.log(state.screen, action, "a6b17fd9")
      state.screen = .onboarding(.supervision(.setup(.accountNowUnder18)))
      return .none

    case (.onboarding(.supervision(.setup(.siblingAlternativeExplain))), .primary):
      self.deps.log(state.screen, action, "5cdeb42b")
      state.screen = .onboarding(.supervision(.setup(.siblingAlternativeCons)))
      return .none

    case (.onboarding(.supervision(.setup(.siblingAlternativeExplain))), .secondary):
      self.deps.log(state.screen, action, "8c2ed1a5")
      state.screen = .onboarding(.supervision(.setup(.freeAlternativesHub)))
      return .none

    case (.onboarding(.supervision(.setup(.siblingAlternativeCons))), .primary):
      self.deps.log(state.screen, action, "f3a1b2c4")
      state.screen = .onboarding(.supervision(.setup(.siblingAlternativeInstructions)))
      return .none

    case (.onboarding(.supervision(.setup(.siblingAlternativeCons))), .secondary):
      self.deps.log(state.screen, action, "d4e5f6a7")
      state.screen = .onboarding(.supervision(.setup(.freeAlternativesHub)))
      return .none

    case (.onboarding(.supervision(.setup(.siblingAlternativeInstructions))), .primary):
      self.deps.log(state.screen, action, "e5f6a7b8")
      state.screen = .onboarding(.supervision(.setup(.accountNowUnder18)))
      return .none

    case (.onboarding(.supervision(.setup(.accountNowUnder18))), .primary):
      self.deps.log(state.screen, action, "b7c8d9e0")
      state.screen = .onboarding(.happyPath(.confirmParentIsOnboarding))
      return .none

    case (.onboarding(.supervision(.setup(.appleConfiguratorExplain))), .primary):
      self.deps.log(state.screen, action, "c6d7e8f9")
      state.screen = .onboarding(.supervision(.setup(.appleConfiguratorCons(step: 1))))
      return .none

    case (.onboarding(.supervision(.setup(.appleConfiguratorExplain))), .secondary):
      self.deps.log(state.screen, action, "a0b1c2d3")
      state.screen = .onboarding(.supervision(.setup(.freeAlternativesHub)))
      return .none

    case (.onboarding(.supervision(.setup(.appleConfiguratorCons(let step)))), .primary):
      self.deps.log(state.screen, action, "e4f5a6b7")
      if step < 3 {
        state.screen = .onboarding(.supervision(.setup(.appleConfiguratorCons(step: step + 1))))
      }
      return .none

    case (.onboarding(.supervision(.setup(.appleConfiguratorCons))), .secondary):
      self.deps.log(state.screen, action, "c8d9e0f1")
      state.screen = .onboarding(.supervision(.setup(.freeAlternativesHub)))
      return .none

    case (.onboarding(.supervision(.setup(.explainNeedSomeoneElse))), .primary):
      self.deps.log(state.screen, action, "39d56d1a")
      return self.generateSupervisionClaimCode(
        reuseExistingValidCode: true,
        showGeneratingScreen: true,
      )

    case (.onboarding(.supervision(.setup(.explainNeedSomeoneElse))), .secondary):
      self.deps.log(state.screen, action, "f0a2d33c")
      state.screen = .onboarding(.supervision(.setup(.selfManagementPlaceholder)))
      return .none

    case (.onboarding(.supervision(.setup(.selfManagementPlaceholder))), .primary):
      self.deps.log(state.screen, action, "84555fc8")
      state.screen = .onboarding(.happyPath(.hiThere))
      return .none

    // the only button on this screen is `retry` for a failure case
    case (.onboarding(.supervision(.setup(.generateSetupCode(_)))), .primary):
      self.deps.log(state.screen, action, "b530239d")
      return self.generateSupervisionClaimCode()

    case (.onboarding(.supervision(.setup(.instructionsForProtector(let code)))), .primary):
      self.deps.log(state.screen, action, "0aea6b12")
      state.screen = .onboarding(.supervision(.setup(.waitingForSupervision(code: code))))
      return .none

    case (.onboarding(.supervision(.setup(.waitingForSupervision))), _):
      self.deps.log(state.screen, action, "65dc5864")
      return .none

      // MARK: - supervision resume

    case (.onboarding(.supervision(.resume(.codeNotClaimed(let code)))), .primary):
      self.deps.log(state.screen, action, "ad87c533")
      state.screen = .onboarding(.supervision(.setup(.instructionsForProtector(code: code))))
      return .none

    case (.onboarding(.supervision(.resume(.codeExpired))), .primary):
      self.deps.log(state.screen, action, "b496da4b")
      return self.generateSupervisionClaimCode(showGeneratingScreen: true)

    case (.onboarding(.supervision(.resume(.codeExpired))), .secondary):
      self.deps.log(state.screen, action, "560908e7")
      self.deps.sharedStorage.clearPendingSupervisionCode()
      state.screen = .onboarding(.happyPath(.hiThere))
      return .none

    case (.onboarding(.supervision(.resume(.codeClaimedNotSupervised))), .primary):
      self.deps.log(state.screen, action, "6dd407cb")
      state.screen = .launching
      return .send(.programmatic(.appDidLaunch))

    case (.onboarding(.supervision(.resume(.retrySupervision))), .primary):
      self.deps.log(state.screen, action, "d664b520")
      if let code = self.deps.sharedStorage.loadPendingSupervisionCode()?.code {
        state.screen = .onboarding(.supervision(.setup(.instructionsForProtector(code: code))))
      } else {
        self.deps.log(state.screen, action, "00b0c478", extra: "unreachable missing code")
        state.screen = .onboarding(.supervision(.setup(.explainNeedSomeoneElse)))
      }
      return .none

    case (.onboarding(.supervision(.resume(.profileRemovedRecovery))), .primary):
      self.deps.log(state.screen, action, "4693f615")
      state.screen = .onboarding(.supervision(.resume(.promptInstallProfile)))
      return .none

    case (.onboarding(.supervision(.resume(.promptInstallProfile))), .primary):
      self.deps.log(state.screen, action, "7b5b4726")
      state.screen = .onboarding(.supervision(.resume(.explainProfileDownload)))
      return .none

    case (.onboarding(.supervision(.resume(.explainProfileDownload))), .primary):
      self.deps.log(state.screen, action, "0cc9747d")
      return .run { [deps = self.deps] send in
        let deviceId = deps.sharedStorage.loadAccountConnection()?.deviceId ?? .init(6)
        let profileUrl = URL.profileDownload(deviceId: deviceId)
        await send(.programmatic(.setScreen(.onboarding(
          .supervision(.resume(.installingProfile(profileUrl: profileUrl))),
        ))))
      }

    case (.onboarding(.supervision(.resume(.installingProfile(_)))), _):
      self.deps.log(state.screen, action, "f2e0454e")
      state.screen = .onboarding(.supervision(.resume(.profileDownloaded)))
      return .none

    case (.onboarding(.supervision(.resume(.profileDownloaded))), .primary):
      self.deps.log(state.screen, action, "c179832d")
      state.screen = .onboarding(.supervision(.resume(.profileNotRemovableWarning)))
      return .none

    case (.onboarding(.supervision(.resume(.profileNotRemovableWarning))), .primary):
      self.deps.log(state.screen, action, "a1d3f8b2")
      state.screen = .onboarding(.supervision(.resume(.explainProfileInstall())))
      return .none

    case (.onboarding(.supervision(.resume(.explainProfileInstall))), .primary):
      self.deps.log(state.screen, action, "ee2f2b76")
      state.screen = .onboarding(.supervision(.resume(.verifyingProfileInstall(didError: false))))
      return .run { [deps = self.deps] send in
        await send(.programmatic(deps.pollForFilter()))
      }

    case (.onboarding(.supervision(.resume(.verifyingProfileInstall))), .primary):
      self.deps.log(state.screen, action, "d0d44fe4")
      state.screen = .onboarding(.supervision(.resume(.verifyingProfileInstall(didError: false))))
      return .run { [deps = self.deps] send in
        await send(.programmatic(deps.pollForFilter()))
      }

    case (.onboarding(.supervision(.resume(.profileInstalled))), .primary):
      self.deps.log(state.screen, action, "4af7783e")
      if state.onboarding.isProfileRecovery {
        state.onboarding.isProfileRecovery = false
        state.screen = .running(state: .connected)
        return .none
      }
      let childName = self.deps.sharedStorage.loadAccountConnection()?.childName
      state.screen = .onboarding(.supervision(.resume(.websiteWarning(childName: childName))))
      return .none

    case (.onboarding(.supervision(.resume(.websiteWarning(_)))), .primary):
      self.deps.log(state.screen, action, "8aa4790f")
      state.screen = .onboarding(.supervision(.resume(.promptClearCache)))
      return .none

    case (.onboarding(.supervision(.resume(.promptClearCache))), .primary):
      self.deps.log(state.screen, action, "acfc7894")
      state.onboarding.clearCache = .init(context: .onboarding)
      return .none

    case (.onboarding(.supervision(.resume(.promptClearCache))), .secondary):
      self.deps.log(state.screen, action, "7d8b61d0")
      state.screen = .onboarding(.happyPath(.requestAppStoreRating))
      return .run { [deps = self.deps] _ in
        deps.sharedStorage.clearPendingSupervisionCode()
      }

    case (.onboarding(.supervision(.resume(.networkError))), .primary):
      self.deps.log(state.screen, action, "be1c3c10")
      state.screen = .launching
      return .send(.programmatic(.appDidLaunch))

    case (.onboarding(.supervision(.resume(.requiresSubscription))), .primary):
      self.deps.log(state.screen, action, "b5e8076e")
      state.screen = .launching
      return .send(.programmatic(.appDidLaunch))

    // MARK: - error paths

    case (.onboarding(.authFail(.invalidAccount(.letsFigureThisOut))), .primary):
      self.deps.log(state.screen, action, "285efafb")
      state.screen = .onboarding(.authFail(.invalidAccount(.confirmInAppleFamily)))
      return .none

    case (.onboarding(.authFail(.invalidAccount(.confirmInAppleFamily))), .primary):
      self.deps.log(state.screen, action, "e90ff997")
      state.screen = .onboarding(.authFail(.invalidAccount(.confirmIsMinor)))
      return .none

    case (.onboarding(.authFail(.invalidAccount(.confirmInAppleFamily))), .secondary):
      self.deps.log(state.screen, action, "39c52acf")
      state.screen = .onboarding(.appleFamily(.explainRequiredForFiltering))
      return .none

    case (.onboarding(.authFail(.invalidAccount(.confirmInAppleFamily))), .tertiary):
      self.deps.log(state.screen, action, "a9cbe4fe")
      state.screen = .onboarding(.appleFamily(.checkIfInAppleFamily))
      state.onboarding.returningTo = .onboarding(.authFail(.invalidAccount(.confirmInAppleFamily)))
      return .none

    case (.onboarding(.authFail(.invalidAccount(.confirmIsMinor))), .primary):
      self.deps.log(state.screen, action, "9d0d9eac")
      state.screen = .onboarding(.supervision(.setup(.explainSupervision)))
      return .none

    case (.onboarding(.authFail(.invalidAccount(.confirmIsMinor))), .secondary):
      self.deps.log(state.screen, action, "e457cf15")
      state.screen = .onboarding(.authFail(.invalidAccount(.unexpected)))
      return .none

    case (.onboarding(.authFail(.restricted)), .secondary):
      self.deps.log(state.screen, action, "b8422c3a")
      state.screen = .onboarding(.happyPath(.hiThere))
      return .none

    case (.onboarding(.authFail(.authConflict)), .primary):
      self.deps.log(state.screen, action, "7b53bdc0")
      state.screen = .onboarding(.happyPath(.explainTwoInstallSteps))
      return .none

    case (.onboarding(.authFail(.networkError)), .primary):
      self.deps.log(state.screen, action, "16e57d91")
      state.screen = .onboarding(.happyPath(.explainTwoInstallSteps))
      return .none

    case (.onboarding(.authFail(.passcodeRequired)), .primary):
      self.deps.log(state.screen, action, "d2888470")
      state.screen = .onboarding(.happyPath(.explainTwoInstallSteps))
      return .none

    case (.onboarding(.authFail(.authCanceled)), .primary):
      self.deps.log(state.screen, action, "6e3b2c93")
      state.screen = .onboarding(.happyPath(.explainTwoInstallSteps))
      return .none

    case (.onboarding(.authFail(.unexpected)), .primary):
      self.deps.log(state.screen, action, "87c5ad82")
      state.screen = .onboarding(.happyPath(.explainTwoInstallSteps))
      return .none

    case (.onboarding(.installFail(.permissionDenied)), .primary):
      self.deps.log(state.screen, action, "b122af01")
      state.screen = .onboarding(.happyPath(.explainInstallWithDevicePasscode))
      return .none

    case (.onboarding(.installFail(.other)), .primary):
      self.deps.log(state.screen, action, "cf059547")
      state.screen = .onboarding(.happyPath(.explainInstallWithDevicePasscode))
      return .none

    case (.onboarding(.mdmSupervisionExplainer), .primary):
      self.deps.log(state.screen, action, "b4e7f219")
      state.screen = .onboarding(.happyPath(.hiThere))
      return .none

    case (.onboarding(.childIsOnboardingFail), .primary):
      self.deps.log(state.screen, action, "566a3484")
      state.screen = .onboarding(.happyPath(.hiThere))
      return .none

    case (.supervisionSuccessFirstLaunch, .primary):
      self.deps.log(state.screen, action, "aa563df6")
      state.onboarding.deviceSupervised = true
      state.screen = .onboarding(.happyPath(.offerAccountConnect))
      return .none

    default:
      #if DEBUG
        fatalError("Unhandled combination:\n -> btn: .\(btn)\n -> screen: .\(state.screen)")
      #else
        self.deps.log(state.screen, action, "7c039b10", extra: "UNHANDLED ACTION")
        state.screen = state.screen.fallbackDestination(from: btn)
        return .none
      #endif
    }
  }

  func programmatic(state: inout State, action: Action.Programmatic) -> EffectOf<IOSReducer> {
    switch action {
    case .appDidLaunch:
      return .merge(
        // detect current state and set screen
        .run { [deps = self.deps] send in
          // controller proxy also tries to migrate, but we do it here as safeguard
          if await deps.sharedStorage.migrateLegacyData() {
            deps.log("migration performed by app", "5258e97c")
            Witness.appMigrated.emit()
          }

          switch await deps.launchState() {

          case .running(.unconnected):
            await send(.programmatic(.setScreen(.running(state: .notConnected))))

          case .running(.connected(let conn)):
            await send(.programmatic(.setScreen(.running(state: .connected))))
            await deps.receiveAccountConnection(conn)
            deps.sharedStorage.clearPendingSupervisionCode()

          case .onboardingNeeded:
            deps.log("onboarding needed on launch", "7a539f70")
            await send(.programmatic(.setScreen(.onboarding(.happyPath(.hiThere)))))

          case .gertrudeSupervisionReboot(.codeNotClaimed(let code)):
            deps.log("supervision reboot code not claimed", "e9b86e6b")
            await send(.programmatic(
              .setScreen(.onboarding(.supervision(.resume(.codeNotClaimed(code: code))))),
            ))

          case .gertrudeSupervisionReboot(.requiresSubscription(let conn)):
            deps.log("supervision reboot requires subscription", "a7d41f0e")
            await deps.receiveAccountConnection(conn)
            await send(.programmatic(
              .setScreen(.onboarding(.supervision(.resume(.requiresSubscription)))),
            ))

          case .gertrudeSupervisionReboot(.codeClaimedNotSupervised(let conn)):
            deps.log("supervision reboot code claimed not supervised", "80580cd5")
            await deps.receiveAccountConnection(conn)
            await send(.programmatic(
              .setScreen(.onboarding(.supervision(.resume(.codeClaimedNotSupervised)))),
            ))

          case .gertrudeSupervisionReboot(.codeExpired), .gertrudeSupervisionReboot(.codeNotFound):
            deps.log("supervision reboot code expired/not found", "0b15e23f")
            await send(.programmatic(
              .setScreen(.onboarding(.supervision(.resume(.codeExpired)))),
            ))

          case .gertrudeSupervisionReboot(.supervisedButNeedsProfile(let conn)):
            deps.log("supervision reboot supervised but needs profile", "05a47c3a")
            await deps.receiveAccountConnection(conn)
            await send(.programmatic(
              .setScreen(.onboarding(.supervision(.resume(.promptInstallProfile)))),
            ))

          case .gertrudeSupervisionReboot(.serverClientDisagreement(let conn)):
            deps.log("server/client supervision state disagreement", "94991de7")
            await deps.receiveAccountConnection(conn)
            await send(.programmatic(
              .setScreen(.onboarding(.supervision(.resume(.promptInstallProfile)))),
            ))

          case .configuratorSupervisionFirstLaunch:
            deps.log("configurator supervision success first launch", "bad8adcc")
            await send(.programmatic(.setScreen(.supervisionSuccessFirstLaunch)))

          case .profileRemovedRecovery(let conn):
            deps.log("profile removed recovery for supervised user", "4f22bd20")
            await deps.receiveAccountConnection(conn)
            await send(.programmatic(.setProfileRecovery))
            await send(.programmatic(
              .setScreen(.onboarding(.supervision(.resume(.profileRemovedRecovery)))),
            ))

          case .filterNoLongerRunning:
            // NB: if they remove the filter via Settings then launch app, we'll get here
            deps.log("non-running filter w/ stored groups", "23c207e2")
            await send(.programmatic(.setScreen(.onboarding(.happyPath(.hiThere)))))

          case .gertrudeSupervisionReboot(.networkError):
            deps.log("supervision reboot network error after retries", "b7f3a2d1")
            await send(.programmatic(
              .setScreen(.onboarding(.supervision(.resume(.networkError)))),
            ))
          }
          if let featureFlag = try? await deps.api.connectAccountFeatureFlag() {
            await send(.programmatic(.receivedConnectAccountFeatureFlag(featureFlag)))
          }
          if let ids = deps.sharedStorage.loadDisabledBlockGroupIds() {
            await send(.programmatic(.receivedDisabledBlockGroupIds(ids)))
          }
          if let groups = deps.sharedStorage.loadAllBlockGroups() {
            await send(.programmatic(.receivedAllBlockGroups(groups)))
          } else if let deviceId = await deps.device.deviceId(),
                    let groups = try? await deps.api.fetchAllBlockGroups(deviceId),
                    !groups.isEmpty {
            deps.sharedStorage.saveAllBlockGroups(groups)
            await send(.programmatic(.receivedAllBlockGroups(groups)))
          }
        },
        // handle first launch
        .run { [deps = self.deps] send in
          if let firstLaunch = deps.sharedStorage.loadFirstLaunchDate() {
            await send(.programmatic(.setFirstLaunch(firstLaunch)))
          } else {
            let now = deps.now
            deps.sharedStorage.saveFirstLaunchDate(now)
            await send(.programmatic(.setFirstLaunch(now)))
            let deviceId = await deps.device.deviceId()
            // prefetch the default block groups for onboarding
            let defaultRules = try? await deps.api.fetchDefaultBlockRules(deviceId)
            if let defaultRules, !defaultRules.isEmpty {
              deps.sharedStorage.saveProtectionMode(.onboarding(defaultRules))
            } else {
              deps.sharedStorage
                .saveProtectionMode(.onboarding(BlockRule.Legacy.defaults.map(\.current)))
            }
            // prefetch block group catalog so it's ready when user reaches opt-out screen
            if let deviceId,
               let groups = try? await deps.api.fetchAllBlockGroups(deviceId),
               !groups.isEmpty {
              deps.sharedStorage.saveAllBlockGroups(groups)
              await send(.programmatic(.receivedAllBlockGroups(groups)))
            }
            await deps.api.logEvent(
              "8d35f043",
              "[onboarding] first launch, region: `\(deps.locale.region?.identifier ?? "(nil)")`",
            )
          }
        },
        // safeguard in case app crashed trying to fill the disk
        .run { [deps = self.deps] send in
          await deps.device.deleteCacheFillDir()
        },
        // fetch cross-promo campaigns for later presentation
        .run { [deps = self.deps] send in
          if let output = try? await deps.api.crossPromos(), !output.promos.isEmpty {
            await send(.programmatic(.receivedCrossPromos(output)))
          }
        },
      )

    case .receivedCrossPromos(let output):
      let dropped = output.promos.filter { !$0.hasGuaranteedExit }
      state.crossPromos = .init(promos: output.promos.filter(\.hasGuaranteedExit))
      return .merge(
        self.logUnpresentableCrossPromos(dropped),
        self.presentHomeCrossPromo(&state),
      )

    case .appWillTerminate:
      return .cancel(id: ClearCacheFeature.CancelId.cacheClearUpdates)

    case .setFirstLaunch(let date):
      state.onboarding.firstLaunch = date
      return .none

    case .setScreen(let screen):
      state.screen = screen
      if screen.isRunning {
        return self.presentHomeCrossPromo(&state)
      }
      return .none

    case .setProfileRecovery:
      state.onboarding.isProfileRecovery = true
      return .none

    case .authorizationSucceeded:
      if state.screen == .onboarding(.happyPath(.dontGetTrickedPreAuth)) {
        self.deps.log(action, "021834f6")
      } else {
        self.deps.unexpected(state.screen, action, "e30624c6")
      }
      state.screen = .onboarding(.happyPath(.explainInstallWithDevicePasscode))
      return .none

    case .authorizationFailed(let err):
      if state.screen != .onboarding(.happyPath(.dontGetTrickedPreAuth)) {
        self.deps.unexpected(state.screen, action, "fa49f256")
      }
      let errStr = String(reflecting: err)
      switch err {
      case .invalidAccountType:
        self.deps.log(action, "2bcf3d96", extra: "invalid account: \(errStr)")
        state.screen = .onboarding(.authFail(.invalidAccount(.letsFigureThisOut)))
      case .authorizationCanceled:
        self.deps.log(action, "e220a765", extra: "auth canceled: \(errStr)")
        state.screen = .onboarding(.authFail(.authCanceled))
      case .restricted:
        self.deps.log(action, "6f0a66e4", extra: "restricted: \(errStr)")
        state.screen = .onboarding(.authFail(.restricted))
      case .authorizationConflict:
        self.deps.log(action, "24220209", extra: "auth conflict: \(errStr)")
        state.screen = .onboarding(.authFail(.authConflict))
      case .networkError:
        self.deps.log(action, "104a7ef6", extra: "network: \(errStr)")
        state.screen = .onboarding(.authFail(.networkError))
      case .passcodeRequired:
        self.deps.log(action, "d2e2ee7c", extra: "passcode req: \(errStr)")
        state.screen = .onboarding(.authFail(.passcodeRequired))
      case .other, .unexpected:
        self.deps.log(action, "f4ed05fd", extra: "other/unexpected: \(errStr)")
        state.screen = .onboarding(.authFail(.unexpected))
      }
      return .none

    case .installSucceeded:
      if state.screen == .onboarding(.happyPath(.dontGetTrickedPreInstall)) {
        self.deps.log(action, "421d373b")
      } else {
        self.deps.unexpected(state.screen, action, "c98b9525")
      }
      state.screen = .onboarding(.happyPath(.offerAccountConnect))
      return .run { [deps = self.deps] _ in
        deps.sharedStorage.saveDisabledBlockGroupIds([])
      }

    case .installFailed(let err):
      if state.screen != .onboarding(.happyPath(.dontGetTrickedPreInstall)) {
        self.deps.unexpected(state.screen, action, "93958bd1")
      }
      switch err {
      case .configurationPermissionDenied:
        self.deps.log(action, "0dc1632a", extra: "install failed, permission denied")
        state.screen = .onboarding(.installFail(.permissionDenied))
      case .configurationCannotBeRemoved, .configurationDisabled, .configurationInternalError,
           .configurationInvalid, .configurationStale, .unexpected:
        self.deps.log(action, "321558ed", extra: "other error: \(String(reflecting: err))")
        state.screen = .onboarding(.installFail(.other(err)))
      }
      return .none

    case .receivedConnectAccountFeatureFlag(let feature):
      state.onboarding.connectFeature = feature
      return .none

    case .receivedAllBlockGroups(let groups):
      state.allBlockGroups = groups
      return .none

    case .receivedDisabledBlockGroupIds(let ids):
      state.disabledBlockGroupIds = ids
      return .none

    case .supervisionCodeGenerated(let code):
      self.deps.log(action, "fcba8692")
      state.screen = .onboarding(.supervision(.setup(.instructionsForProtector(code: code))))
      return .none

    case .supervisionCodeGenerationFailed:
      self.deps.log(action, "498796d3")
      state.screen = .onboarding(.supervision(.setup(.generateSetupCode(didError: true))))
      return .none

    case .filterVerified:
      self.deps.log(action, "a7e31b8f")
      state.screen = .onboarding(.supervision(.resume(.profileInstalled)))
      return .run { [deps = self.deps] _ in
        _ = try? await deps.api.markSupervisionProfileInstalled()
      }

    case .filterVerificationFailed:
      self.deps.log(action, "c4d92e1a")
      state.screen = .onboarding(.supervision(.resume(.verifyingProfileInstall(didError: true))))
      return .none

    case .appDidEnterForeground
      where state.screen == .onboarding(.supervision(.resume(.explainProfileInstall()))):
      state.screen = .onboarding(.supervision(.resume(.explainProfileInstall(regainedFocus: true))))
      return .none

    case .appDidEnterForeground:
      return self.presentHomeCrossPromo(&state)

    case .appDidEnterBackground:
      return .none
    }
  }

  func destination(state: inout State, action: Destination.Action) -> EffectOf<IOSReducer> {
    switch action {
    case .crossPromo(.delegate(.ctaTapped(let slot))):
      self.closeCrossPromo(&state, event: .cta, ctaSlot: slot)
    case .crossPromo(.delegate(.dismissed)):
      self.closeCrossPromo(&state, event: .dismiss, ctaSlot: nil)
    default:
      .none
    }
  }
}

extension IOSReducer.Deps {
  func receiveAccountConnection(_ conn: ChildIOSDeviceData_v2) async {
    await self.api.setAccountConnection(conn)
    self.sharedStorage.saveAccountConnection(conn)
  }

  func pollForFilter() async -> IOSReducer.Action.Programmatic {
    for _ in 0 ..< 6 {
      if await self.systemExtension.filterRunning() {
        return .filterVerified
      }
      try? await self.clock.sleep(for: .milliseconds(500))
    }
    return .filterVerificationFailed
  }
}

extension IOSReducer {
  func generateSupervisionClaimCode(
    reuseExistingValidCode: Bool = false,
    showGeneratingScreen: Bool = false,
  ) -> EffectOf<IOSReducer> {
    .run { [deps = self.deps] send in
      if reuseExistingValidCode,
         let data = deps.sharedStorage.loadPendingSupervisionCode(),
         data.expiresAt > deps.now {
        await send(.programmatic(.setScreen(.onboarding(
          .supervision(.setup(.instructionsForProtector(code: data.code))),
        ))))
        return
      }

      if showGeneratingScreen {
        await send(.programmatic(.setScreen(.onboarding(
          .supervision(.setup(.generateSetupCode())),
        ))))
      }

      do {
        let data = try await deps.api.createSupervisionClaimCode()
        deps.sharedStorage.savePendingSupervisionCode(data)
        await send(.programmatic(.supervisionCodeGenerated(code: data.code)))
      } catch {
        await send(.programmatic(.supervisionCodeGenerationFailed))
      }
    }
  }

  func transitionToOptOutOrSkip(state: inout State) -> EffectOf<IOSReducer> {
    guard !state.allBlockGroups.isEmpty else {
      state.screen = .onboarding(.happyPath(.promptClearCache))
      return .run { [deps = self.deps] _ in
        deps.log("UNEXPECTED: no block groups at opt-out screen", "ebedab78")
        deps.sharedStorage.saveDisabledBlockGroupIds([])
      }
    }
    state.screen = .onboarding(.happyPath(.optOutBlockGroups))
    return .none
  }

  func isBuildAhead(of appStoreVersion: String?) -> Bool {
    guard let appStoreVersion else { return false }
    let appVersion = self.deps.device.installedVersion()
    let app = appVersion.split(separator: ".").compactMap { Int($0) }
    let store = appStoreVersion.split(separator: ".").compactMap { Int($0) }
    guard app.count >= 3, store.count >= 3 else { return false }
    if app[0] != store[0] { return app[0] > store[0] }
    if app[1] != store[1] { return app[1] > store[1] }
    return app[2] > store[2]
  }
}
