import ComposableArchitecture
import Foundation

struct AppReducer: Reducer, Sendable {
  @ObservableState
  struct State: Equatable, Sendable {
    var selectedTabID: Tab.State.ID?
    var tabs: IdentifiedArrayOf<Tab.State> = []
  }

  @CasePathable
  enum Action: Equatable, Sendable {
    case application(ApplicationFeature.Action)
    case tabs(IdentifiedActionOf<Tab>)
  }

  var body: some ReducerOf<Self> {
    ApplicationFeature.RootReducer()
      .forEach(\.tabs, action: \.tabs) {
        Tab()
      }
  }
}
