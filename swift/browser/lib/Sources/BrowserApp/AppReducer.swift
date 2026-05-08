import ComposableArchitecture
import Foundation

struct AppReducer: Reducer, Sendable {
  struct State: Equatable, Sendable {
    var didFinishLaunching = false
  }

  enum Action: Equatable, Sendable {
    case application(ApplicationFeature.Action)
  }

  var body: some ReducerOf<Self> {
    ApplicationFeature.RootReducer()
  }
}
