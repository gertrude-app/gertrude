import ComposableArchitecture
import Foundation

enum ApplicationFeature {
  typealias Action = ApplicationAction

  struct RootReducer: Reducer {
    typealias State = AppReducer.State
    typealias Action = AppReducer.Action

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      switch action {
      case .application(.didFinishLaunching):
        state.didFinishLaunching = true
        return .none
      }
    }
  }
}
