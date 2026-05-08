import ComposableArchitecture
import Foundation

struct Tab: Reducer, Sendable {
  @ObservableState
  struct State: Equatable, Identifiable, Sendable {
    let id: UUID
    var url: URL
  }

  enum Action: Equatable, Sendable {}

  var body: some ReducerOf<Self> {
    EmptyReducer()
  }
}
