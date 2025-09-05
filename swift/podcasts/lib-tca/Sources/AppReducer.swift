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

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .appDidLaunch:
        // print(saveToken("foobar", for: "gertie"))
        // print(loadToken(for: "gertie") ?? "no token")
        .none
      }
    }
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
