import BlockerRoute

// swiftformat:disable extensionAccessControl
import ComposableArchitecture
import GertieTcaFeatures
import LibClients
import TaggedTime

extension IOSReducer {
  @Reducer
  public enum Destination {
    case info(InfoFeature)
    case crossPromo(CrossPromoFeature)
  }

  @ObservableState
  public struct State: Equatable {
    public var screen: Screen = .launching
    public var allBlockGroups: [GetBlockGroups.BlockGroupInfo] = []
    public var appUpdate = AppUpdateGateFeature.State()
    public var disabledBlockGroupIds: [UUID] = []
    public var onboarding: OnboardingState = .init()
    public var crossPromos: CrossPromos.Output = .init(promos: [])

    @Presents
    public var destination: Destination.State?

    public init(
      screen: IOSReducer.Screen = .launching,
      allBlockGroups: [GetBlockGroups.BlockGroupInfo] = [],
      disabledBlockGroupIds: [UUID] = [],
      onboarding: OnboardingState = .init(),
    ) {
      self.screen = screen
      self.allBlockGroups = allBlockGroups
      self.disabledBlockGroupIds = disabledBlockGroupIds
      self.onboarding = onboarding
    }

    public struct OnboardingState: Equatable {
      public var firstLaunch: Date?
      public var returningTo: Screen?
      public var deviceSupervised: Bool = false
      public var isProfileRecovery: Bool = false
      public var clearCache: ClearCacheFeature.State?
      public var crossPromo: CrossPromoFeature.State?
      public var connect: ConnectAccount.State?
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
      case explainPermissionDependsOnAge
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
        case adultNeedsSupervision
        case whatIsSupervisedMode
        case supervisedDeviceReassurance
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
        case codeExpired
        case codeClaimedNotSupervised
        case retrySupervision
        case profileRemovedRecovery
        case promptInstallProfile
        case explainProfileDownload
        case installingProfile(profileUrl: URL)
        case profileDownloaded
        case profileNotRemovableWarning
        case explainProfileInstall(regainedFocus: Bool = false)
        case verifyingProfileInstall(didError: Bool = false)
        case profileInstalled
        case websiteWarning(childName: String?)
        case promptClearCache
        case networkError
        case requiresSubscription
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

    public var isRunning: Bool {
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

extension IOSReducer.Destination.State: Equatable {}
extension IOSReducer.Destination.Action: Equatable {}
