// swiftformat:disable extensionAccessControl
import ComposableArchitecture
import IOSRoute
import LibClients
import TaggedTime

extension IOSReducer {
  @Reducer(state: .equatable, action: .equatable)
  public enum Destination {
    case connectAccount(ConnectAccount)
    case info(InfoFeature)
  }

  @ObservableState
  public struct State: Equatable {
    public var screen: Screen = .launching
    public var disabledBlockGroups: [BlockGroup] = []
    public var onboarding: OnboardingState = .init()

    @Presents
    public var destination: Destination.State?

    public init(
      screen: IOSReducer.Screen = .launching,
      disabledBlockGroups: [BlockGroup] = [],
      onboarding: OnboardingState = .init(),
    ) {
      self.screen = screen
      self.disabledBlockGroups = disabledBlockGroups
      self.onboarding = onboarding
    }

    public struct OnboardingState: Equatable {
      public var firstLaunch: Date?
      public var returningTo: Screen?
      public var deviceSupervised: Bool = false
      public var isProfileRecovery: Bool = false
      public var clearCache: ClearCacheFeature.State?
      public var connectFeature = ConnectAccountFeatureFlag.Output(isEnabled: false)

      public init(
        firstLaunch: Date? = nil,
        returningTo: IOSReducer.Screen? = nil,
      ) {
        self.firstLaunch = firstLaunch
        self.returningTo = returningTo
      }

      mutating func takeReturningTo() -> IOSReducer.Screen? {
        let returningTo = self.returningTo
        self.returningTo = nil
        return returningTo
      }
    }
  }

  public enum Onboarding: Equatable {
    case happyPath(HappyPath)
    case appleFamily(AppleFamily)
    case supervision(Supervision)
    case authFail(AuthFail)
    case installFail(InstallFail)

    case onParentDeviceFail
    case childIsOnboardingFail
    case mdmSupervisionExplainer

    public enum HappyPath: Equatable {
      case hiThere
      case timeExpectation
      case confirmChildsDevice
      case explainMinorOrSupervised
      case confirmMinorDevice
      case confirmParentIsOnboarding
      case confirmInAppleFamily
      case explainTwoInstallSteps
      case explainAuthWithParentAppleAccount
      case dontGetTrickedPreAuth
      case explainInstallWithDevicePasscode
      case dontGetTrickedPreInstall
      case offerAccountConnect
      case explainAccountConnect
      case connectSuccess
      case optOutBlockGroups
      case promptClearCache
      case requestAppStoreRating
      case doneQuit
    }

    public enum AppleFamily: Equatable {
      case explainRequiredForFiltering
      case explainSetupFreeAndEasy
      case howToSetupAppleFamily
      case explainWhatIsAppleFamily
      case checkIfInAppleFamily
    }

    public enum Supervision: Equatable {
      case setup(Setup)
      case resume(Resume)

      public enum Setup: Equatable {
        case explainSupervision
        case costAndBranchPoint
        case freeAlternativesHub
        case birthdayAlternativeExplain
        case birthdayAlternativeCons
        case birthdayAlternativeInstructions
        case siblingAlternativeExplain
        case siblingAlternativeCons
        case siblingAlternativeInstructions
        case appleConfiguratorExplain
        case appleConfiguratorCons(step: Int = 1)
        case accountNowUnder18
        case explainNeedSomeoneElse
        case selfManagementPlaceholder
        case generateSetupCode(didError: Bool = false)
        case instructionsForProtector(code: Int)
        case waitingForSupervision(code: Int)
      }

      // these states occur after rebooting into supervision
      public enum Resume: Equatable {
        case codeNotClaimed(code: Int)
        case codeClaimedNotSupervised(regainedFocus: Bool = false)
        case retrySupervision
        case profileRemovedRecovery
        case promptInstallProfile
        case explainProfileDownload
        case installingProfile(profileUrl: URL)
        case profileNotRemovableWarning
        case explainProfileInstall(regainedFocus: Bool = false)
        case verifyingProfileInstall(didError: Bool = false)
        case profileInstalled
        case promptClearCache
        case networkError
      }
    }

    public enum AuthFail: Equatable {
      case invalidAccount(InvalidAccount)
      case authConflict
      case authCanceled
      case restricted
      case passcodeRequired
      case networkError
      case unexpected

      public enum InvalidAccount: Equatable {
        case letsFigureThisOut
        case confirmInAppleFamily
        case confirmIsMinor
        case unexpected
      }
    }

    public enum InstallFail: Equatable {
      case permissionDenied
      case other(FilterInstallError)
    }
  }

  public enum RunningState: Equatable {
    case notConnected
    case connected
  }

  public enum Screen: Equatable {
    case launching
    case onboarding(Onboarding)
    case supervisionSuccessFirstLaunch
    case running(state: RunningState = .notConnected)

    var isRunning: Bool {
      if case .running = self { return true }
      return false
    }
  }

  public enum Connecting: Equatable {
    case enteringCode(String)
    case connecting
    case failedToConnect
    case connectSuccess
  }
}
