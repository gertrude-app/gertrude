import ComposableArchitecture
import IOSRoute
import LibClients

public extension IOSReducer {
  @CasePathable
  enum Action: Equatable {
    case interactive(Interactive)
    case programmatic(Programmatic)
    case destination(PresentationAction<Destination.Action>)

    @CasePathable
    public enum Interactive: Equatable {
      public enum OnboardingBtn: Equatable {
        case primary
        case secondary
        case tertiary
        case quaternary
      }

      case onboardingClearCache(ClearCacheFeature.Action)
      case onboardingBtnTapped(OnboardingBtn, String)
      case blockGroupToggled(UUID)
      case sheetDismissed
      case receivedShake
      case infoBtnTapped
    }

    public enum Programmatic: Equatable {
      case appDidLaunch
      case receivedCrossPromos(CrossPromos.Output)
      case appWillTerminate
      case appDidEnterForeground
      case appDidEnterBackground
      case setFirstLaunch(Date)
      case setScreen(Screen)
      case authorizationSucceeded
      case authorizationFailed(AuthFailureReason)
      case installSucceeded
      case installFailed(FilterInstallError)
      case receivedConnectAccountFeatureFlag(ConnectAccountFeatureFlag.Output)
      case receivedAllBlockGroups([GetBlockGroups.BlockGroupInfo])
      case receivedDisabledBlockGroupIds([UUID])
      case supervisionCodeGenerated(code: Int)
      case supervisionCodeGenerationFailed
      case setProfileRecovery
      case filterVerified
      case filterVerificationFailed
    }
  }
}
