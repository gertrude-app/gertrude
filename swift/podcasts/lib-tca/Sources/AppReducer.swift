import ComposableArchitecture

@Reducer
public struct AppReducer {
  @ObservableState
  public struct State: Equatable {
    public var screen: Screen = .launching
    public init() {}
  }

  public enum Action: Equatable {
    case appDidLaunch
  }

  public init() {}
}

public enum Screen: Equatable {
  case launching
  case onboarding
}

public enum OnboardingScreen: Equatable {
  case hiThere
  case areYouTheParent
  case explainSetPin
}
