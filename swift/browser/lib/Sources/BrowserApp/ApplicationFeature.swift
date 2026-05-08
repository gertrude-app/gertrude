import ComposableArchitecture
import Foundation

enum ApplicationFeature {
  typealias Action = ApplicationAction

  struct RootReducer: Reducer {
    typealias State = AppReducer.State
    typealias Action = AppReducer.Action

    @Dependency(\.uuid) var uuid

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      switch action {
      case .application(.didFinishLaunching):
        let tabID = self.uuid()
        state.tabs.append(Tab.State(
          id: tabID,
          url: URL(string: "https://gertrude.app")!,
        ))
        state.selectedTabID = tabID
        return .none
      case .tabs:
        return .none
      }
    }
  }
}
